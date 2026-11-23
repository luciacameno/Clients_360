{#
  Las listas del iPad y la base de las recomendaciones.
  Una fila por clienta x producto x tipo de señal:
  - interes    · R6: temperatura del interés (sin productos comprados ni devueltos)
  - carrito    · R7: carrito abandonado (sin compra posterior en ningún canal)
  - devolucion · R8: productos devueltos, con su último motivo
#}
with reference as (  -- R0: la fecha de referencia ("hoy" para el modelo)

    select coalesce(
        try_to_timestamp_ntz('{{ var("reference_date") }}'),
        (select max(event_ts) from {{ ref('fct_web_events') }})
    ) as reference_ts

),

bought_or_returned as (

    select distinct customer_key, product_key
    from {{ ref('fct_sales') }}
    where customer_key <> '-1'

),

-- ── R6 · Interés ─────────────────────────────────────────────────────────
interactions as (

    select events.customer_key, events.product_key, events.event_ts, events.action
    from {{ ref('fct_web_events') }} events
    cross join reference
    where events.customer_key <> '-1'
      and events.action in ('view_item', 'add_to_cart')
      and events.event_ts <= reference.reference_ts
      and events.event_ts >= dateadd(day, -{{ var('interest_lookback_days') }}, reference.reference_ts)

),

interest as (

    select
        interactions.customer_key,
        interactions.product_key,
        sum(
            iff(interactions.action = 'add_to_cart',
                {{ var('interest_weight_cart') }}, {{ var('interest_weight_view') }})
            * power(0.5,
                datediff('second', interactions.event_ts, reference.reference_ts) / 86400
                / {{ var('interest_half_life_days') }})
        )                                   as interest_score,
        max(interactions.event_ts)          as last_interaction_ts
    from interactions
    cross join reference
    group by interactions.customer_key, interactions.product_key

),

interest_signals as (

    select
        interest.customer_key,
        interest.product_key,
        'interes'                           as signal_type,
        interest.interest_score,
        case
            when interest.interest_score >= {{ var('interest_hot_threshold') }}  then 'caliente'
            when interest.interest_score >= {{ var('interest_warm_threshold') }} then 'templado'
            else 'frio'
        end                                 as temperature,
        interest.last_interaction_ts,
        null::number                        as days_since_cart,
        null::varchar                       as return_reason
    from interest
    left join bought_or_returned done
           on interest.customer_key = done.customer_key
          and interest.product_key = done.product_key
    where done.customer_key is null

),

-- ── R7 · Carritos abandonados ────────────────────────────────────────────
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

),

cart_signals as (

    select
        last_carts.customer_key,
        last_carts.product_key,
        'carrito',
        null,
        null,
        last_carts.last_cart_ts,
        datediff('day', last_carts.last_cart_ts, reference.reference_ts),
        null
    from last_carts
    cross join reference
    left join purchases
           on last_carts.customer_key = purchases.customer_key
          and last_carts.product_key = purchases.product_key
    where (purchases.last_purchase_ts is null or purchases.last_purchase_ts < last_carts.last_cart_ts)
      and last_carts.last_cart_ts >= dateadd(day, -{{ var('abandoned_cart_window_days') }}, reference.reference_ts)

),

-- ── R8 · Devoluciones ────────────────────────────────────────────────────
return_signals as (

    select
        sales.customer_key,
        sales.product_key,
        'devolucion',
        null,
        null,
        max(sales.sale_ts),
        null,
        max_by(reasons.reason_name, sales.sale_ts)
    from {{ ref('fct_sales') }} sales
    inner join {{ ref('dim_return_reasons') }} reasons
            on sales.return_reason_key = reasons.return_reason_key
    where sales.is_return = 1 and sales.customer_key <> '-1'
    group by sales.customer_key, sales.product_key

),

signals as (

    select * from interest_signals
    union all
    select * from cart_signals
    union all
    select * from return_signals

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