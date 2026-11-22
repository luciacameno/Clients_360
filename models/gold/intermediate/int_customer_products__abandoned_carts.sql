{#
  R7 · Carrito abandonado: el último add_to_cart de cada clienta y producto,
  sin ninguna compra posterior de ese producto en NINGÚN canal, en los últimos N días.
#}
with reference as (

    select coalesce(
        try_to_timestamp_ntz('{{ var("reference_date") }}'),
        (select max(event_ts) from {{ ref('fct_web_events') }})
    ) as reference_ts --si hay una referencia_date vacia , cojo la date_max de fct_web_events

),

last_carts as (

    select customer_key, product_key, max(event_ts) as last_cart_ts
    from {{ ref('fct_web_events') }}
    where customer_key <> '-1' and action = 'add_to_cart'
    group by customer_key, product_key

),

purchases as (

    select customer_key, product_key, max(sale_ts) as last_purchase_ts
    from {{ ref('fct_sales') }}
    where is_sale = 1
    group by customer_key, product_key

)

select
    last_carts.customer_key,
    last_carts.product_key,
    last_carts.last_cart_ts,
    datediff('day', last_carts.last_cart_ts, reference.reference_ts) as days_since_cart
from last_carts
cross join reference
left join purchases
       on last_carts.customer_key = purchases.customer_key
      and last_carts.product_key = purchases.product_key

where (purchases.last_purchase_ts is null or purchases.last_purchase_ts < last_carts.last_cart_ts) --no haya compras o haya sido antes de el carrito
  and last_carts.last_cart_ts >= dateadd(day, -{{ var('abandoned_cart_window_days') }}, reference.reference_ts)