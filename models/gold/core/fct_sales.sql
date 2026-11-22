{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key=['document_id', 'line_number']
    )
}}

{#
  Una fila por línea de venta o devolución, en tienda u online.
  Regla R4: una compra online devuelta en tienda cuenta en el canal de la compra original.
#}
with ticket_lines as (

    select
        lines.ticket_id,
        lines.line_number,
        lines.product_id,
        lines.amount_eur,
        tickets.store_id,
        tickets.customer_key,
        tickets.ticket_ts,
        tickets.ticket_type,
        tickets.identification_method
    from {{ ref('slv_pos__ticket_lines') }} lines
    inner join {{ ref('slv_pos__tickets') }} tickets on lines.ticket_id = tickets.ticket_id

),

returns as (

    select * from {{ ref('slv_pos__returns') }}

),

orders as (

    select orders.order_id, orders.crm_id, orders.order_ts, sessions.channel
    from {{ ref('slv_web__orders') }} orders
    inner join {{ ref('slv_web__sessions') }} sessions on orders.session_id = sessions.session_id

),

accounts as (

    select crm_id, customer_key from {{ ref('slv_crm__accounts') }}

),

store_sales as (

    select
        ticket_lines.ticket_id                                     as document_id,
        ticket_lines.line_number,
        ticket_lines.product_id,
        ticket_lines.amount_eur,
        ticket_lines.ticket_ts                                     as sale_ts,
        ticket_lines.store_id,
        ticket_lines.customer_key,
        coalesce(original_orders.channel, 'tienda')                as channel,
        ticket_lines.ticket_type = 'RETURN'                        as is_return,
        returns.return_reason_id,
        coalesce(returns.original_ticket_id, returns.original_order_id) as original_document_id,
        ticket_lines.identification_method
    from ticket_lines
    left join returns
           on ticket_lines.ticket_id = returns.ticket_id
          and ticket_lines.line_number = returns.line_number
    left join orders original_orders
           on returns.original_order_id = original_orders.order_id

),

online_sales as (

    select
        order_lines.order_id                                       as document_id,
        row_number() over (partition by order_lines.order_id
                           order by order_lines.product_id)        as line_number,
        order_lines.product_id,
        order_lines.unit_price_eur                                 as amount_eur,
        orders.order_ts                                            as sale_ts,
        'ONLINE'                                                   as store_id,
        accounts.customer_key,
        orders.channel,
        false                                                      as is_return,
        null                                                       as return_reason_id,
        null                                                       as original_document_id,
        'login'                                                    as identification_method
    from {{ ref('slv_web__order_lines') }} order_lines
    inner join orders   on order_lines.order_id = orders.order_id
    left join  accounts on orders.crm_id = accounts.crm_id

),

sales as (

    select * from store_sales
    union all
    select * from online_sales

)

select
    to_number(to_char(sale_ts, 'YYYYMMDD'))    as date_key,
    coalesce(customer_key, '-1')               as customer_key,
    product_id                                 as product_key,
    store_id                                   as store_key,
    channel                                    as channel_key,
    coalesce(return_reason_id, '-1')           as return_reason_key,

    document_id,
    line_number,
    original_document_id,
    identification_method,
    sale_ts,

    amount_eur,
    iff(is_return, -1, 1)                      as units,
    iff(is_return, 1, 0)                       as is_return,
    iff(is_return, 0, 1)                       as is_sale
from sales

{% if is_incremental() %}
where sale_ts > (
    select dateadd(day, -{{ var('incremental_lookback_days') }}, max(sale_ts))
    from {{ this }}
)
{% endif %}