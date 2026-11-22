{#
  R10 (2.ª parte) · Top N por clienta:
  1. excluir lo comprado y lo devuelto
  2. un producto con varios motivos: puntuación más alta + 10 por motivo extra
  3. como mucho un producto por subcategoría
  4. ordenar por puntuación; desempate por la interacción más reciente
#}
with candidates as (

    select candidates.*
    from {{ ref('int_recommendations__candidates') }} candidates
    left join (
        select distinct customer_key, product_key from {{ ref('fct_sales') }}
    ) done
           on candidates.customer_key = done.customer_key
          and candidates.product_key = done.product_key
    where done.customer_key is null --ni ha compradp ni devuelto ese producto 

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