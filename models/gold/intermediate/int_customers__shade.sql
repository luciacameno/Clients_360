{#
  R9 · Pasaporte de tono (solo bases y correctores):
  tono confirmado = el del último comprado y NO devuelto;
  tonos descartados = los devueltos por un motivo del grupo 'tono'.
#}
with complexion_sales as (

    select sales.customer_key, sales.product_key, sales.sale_ts, sales.is_return,
           products.shade, products.range_name, reasons.reason_group
    from {{ ref('fct_sales') }} sales
    inner join {{ ref('dim_products') }}       products on sales.product_key = products.product_key
    inner join {{ ref('dim_return_reasons') }} reasons  on sales.return_reason_key = reasons.return_reason_key
    where sales.customer_key <> '-1' and products.is_complexion

),

returned as (

    select distinct customer_key, product_key
    from complexion_sales
    where is_return = 1

),

confirmed as (

    select
        complexion_sales.customer_key,
        max_by(complexion_sales.shade, complexion_sales.sale_ts)      as confirmed_shade,
        max_by(complexion_sales.range_name, complexion_sales.sale_ts) as confirmed_range
    from complexion_sales
    left join returned
           on complexion_sales.customer_key = returned.customer_key
          and complexion_sales.product_key = returned.product_key
    where complexion_sales.is_return = 0 and returned.customer_key is null
    group by complexion_sales.customer_key

),

discarded as (

    select customer_key,
           listagg(distinct shade, ', ') within group (order by shade) as discarded_shades
    from complexion_sales
    where is_return = 1 and reason_group = 'tono'
    group by customer_key

)

select
    coalesce(confirmed.customer_key, discarded.customer_key) as customer_key,
    confirmed.confirmed_shade,
    confirmed.confirmed_range,
    discarded.discarded_shades
from confirmed
full outer join discarded on confirmed.customer_key = discarded.customer_key --mantiene todas las filas de los dos lados. Si hay pareja, las une; si no la hay, rellena el otro lado con NULL