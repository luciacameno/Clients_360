{#
  Cabecera del pedido online. Se mantiene la relación con la cuenta que compra:
  para comprar hay que estar logado, así que el email de la compra identifica la cuenta.
#}
with purchases as (

    select * from {{ ref('stg_web__events') }}
    where action = 'purchase'

),

orders as (

    select
        order_id,
        any_value(session_id) as session_id,
        any_value(user_email) as buyer_email,
        min(event_ts)         as order_ts,
        any_value(currency)   as currency
    from purchases
    group by order_id

)

select
    orders.order_id,
    orders.session_id,
    accounts.crm_id,
    orders.order_ts,
    orders.currency
from orders
left join {{ ref('slv_crm__accounts') }} accounts on orders.buyer_email = accounts.email