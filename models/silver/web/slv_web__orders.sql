{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='order_id'
    )
}}

with purchases as (

    select * from {{ ref('stg_web__events') }}
    where action = 'purchase'

    {% if is_incremental() %}
    -- Pedidos con algún purchase nuevo, recalculados con TODOS sus purchase
    and order_id in (
        select order_id
        from {{ ref('stg_web__events') }}
        where action = 'purchase'
          and _loaded_at > (select max(existing._loaded_at) from {{ this }} as existing)
    )
    {% endif %}

),

orders as (

    select
        order_id,
        any_value(session_id) as session_id,
        any_value(user_email) as buyer_email,
        min(event_ts)         as order_ts,
        any_value(currency)   as currency,
        max(_loaded_at)       as _loaded_at
    from purchases
    group by order_id

)

select
    orders.order_id,
    orders.session_id,
    accounts.crm_id,
    orders.order_ts,
    orders.currency,
    orders._loaded_at
from orders
left join {{ ref('slv_crm__accounts') }} accounts on orders.buyer_email = accounts.email