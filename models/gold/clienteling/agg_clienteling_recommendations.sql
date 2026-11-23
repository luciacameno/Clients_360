
{#
  R10 · Top N por clienta:
  1. candidatos: carritos, interés caliente o templado y productos en su tono
  2. excluir lo comprado y lo devuelto
  3. un producto con varios motivos: puntuación más alta + 10 por motivo extra
  4. como mucho un producto por subcategoría
  5. ordenar por puntuación; desempate por la interacción más reciente
#}
with signals as (

    select * from {{ ref('agg_clienteling_signals') }}

),

carts as (

    select customer_key, product_key, 'carrito' as reason_code,
           iff(days_since_cart <= 14, 90, 70) as base_score,
           last_interaction_ts
    from signals
    where signal_type = 'carrito'

),

interests as (  -- el interés frío no se recomienda

    select customer_key, product_key,
           iff(temperature = 'caliente', 'interes_caliente', 'interes_templado') as reason_code,
           iff(temperature = 'caliente', 80, 40)                                as base_score,
           last_interaction_ts
    from signals
    where signal_type = 'interes' and temperature in ('caliente', 'templado')

),

shade_matches as (  -- el mismo producto de su gama, en su tono confirmado

    select customers.customer_key, products.product_key, 'tono' as reason_code,
           60 as base_score, null::timestamp_ntz as last_interaction_ts
    from {{ ref('agg_clienteling_360') }} customers
    inner join {{ ref('dim_products') }} products
            on products.is_complexion
           and products.shade = customers.confirmed_shade
           and products.range_name = customers.confirmed_range

),

candidates as (

    select all_candidates.*
    from (
        select * from carts
        union all
        select * from interests
        union all
        select * from shade_matches
    ) all_candidates
    left join (
        select distinct customer_key, product_key from {{ ref('fct_sales') }}
    ) done
           on all_candidates.customer_key = done.customer_key
          and all_candidates.product_key = done.product_key
    where done.customer_key is null  -- ni comprado ni devuelto

),

per_product as (

    select
        customer_key,
        product_key,
        max(base_score) + 10 * (count(*) - 1)                           as score,
        max_by(reason_code, base_score)                                 as main_reason, 
        listagg(reason_code, ', ') within group (order by base_score desc) as reason_codes, --agrupar si el producto sale mas de 1 vewz, las razones (en orden de score )
        max(last_interaction_ts)                                        as last_interaction_ts
    from candidates
    group by customer_key, product_key

),

one_per_subcategory as (

    select per_product.*, products.product_name, products.shade
    from per_product
    inner join {{ ref('dim_products') }} products on per_product.product_key = products.product_key
    qualify row_number() over (
        partition by per_product.customer_key, products.subcategory_name
        order by per_product.score desc, per_product.last_interaction_ts desc nulls last --cojo mayor score y ultimo añadido 
    ) = 1

),

ranked as (

    select *,
           row_number() over (
               partition by customer_key
               order by score desc, last_interaction_ts desc nulls last
           ) as recommendation_rank
    from one_per_subcategory

)

select
    customer_key,
    recommendation_rank,
    product_key,
    product_name,
    reason_codes,
    score,
    case main_reason
        when 'carrito'          then 'Lo dejaste en el carrito: ¿quieres probarlo aquí?'
        when 'interes_caliente' then 'Lo has mirado varias veces estos días.'
        when 'tono'             then 'Tenemos tu ' || product_name || ' en tu tono.'
        when 'interes_templado' then 'Hace unas semanas te interesó: ¿le echamos un vistazo?'
    end                         as pitch
from ranked
where recommendation_rank <= {{ var('recommendations_top_n') }}