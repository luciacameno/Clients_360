{#
  Una fila por clienta x producto x tipo de señal (interes, carrito, devolucion).
#}
with signals as (

    select customer_key, product_key, 'interes' as signal_type,
           interest_score, temperature, last_interaction_ts,
           null as days_since_cart, null as return_reason
    from {{ ref('int_customer_products__interest') }}

    union all

    select customer_key, product_key, 'carrito',
           null, null, last_cart_ts, days_since_cart, null
    from {{ ref('int_customer_products__abandoned_carts') }}

    union all

     select sales.customer_key, sales.product_key, 'devolucion',
           null, null,
           max(sales.sale_ts),
           null,
           max_by(reasons.reason_name, sales.sale_ts)
    from {{ ref('fct_sales') }} sales
    inner join {{ ref('dim_return_reasons') }} reasons
            on sales.return_reason_key = reasons.return_reason_key
    where sales.is_return = 1 and sales.customer_key <> '-1'
    group by sales.customer_key, sales.product_key

)

select
    signals.customer_key,
    signals.product_key,
    products.product_name,
    products.brand_name,
    signals.signal_type,
    round(signals.interest_score, 2)  as interest_score,
    signals.temperature,
    signals.last_interaction_ts,
    signals.days_since_cart,
    signals.return_reason
from signals
inner join {{ ref('dim_products') }} products on signals.product_key = products.product_key