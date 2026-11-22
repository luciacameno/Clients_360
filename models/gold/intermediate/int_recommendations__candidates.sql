{#
  R10 (1.ª parte) · Todos los productos que se le podrían ofrecer, cada uno con su motivo
  y su puntuación base. El top 3 se elige en agg
#}
with carts as (

    select customer_key, product_key, 'carrito' as reason_code, --en todas carrito 
           iff(days_since_cart <= 14, 90, 70) as base_score,
           last_cart_ts as last_interaction_ts
    from {{ ref('int_customer_products__abandoned_carts') }}

),

interests as ( --aqui ya eliminamos el frio 

    select customer_key, product_key,
           iff(temperature = 'caliente', 'interes_caliente', 'interes_templado') as reason_code,
           iff(temperature = 'caliente', 80, 40)                                as base_score,
           last_interaction_ts
    from {{ ref('int_customer_products__interest') }}
    where temperature in ('caliente', 'templado')

),

shade_matches as (

    select shade.customer_key, products.product_key, 'tono' as reason_code,
           60 as base_score, null::timestamp_ntz as last_interaction_ts
    from {{ ref('int_customers__shade') }} shade
    inner join {{ ref('dim_products') }} products
            on products.is_complexion
           and products.shade = shade.confirmed_shade
           and products.range_name = shade.confirmed_range

)

select * from carts
union all
select * from interests
union all
select * from shade_matches