{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='event_id'
    )
}}

with events as (

    select * from {{ ref('slv_web__events') }}

    {% if is_incremental() %}
    where _loaded_at > (select max(existing._loaded_at) from {{ this }} as existing)
    {% endif %}

),

sessions as (

    select session_id, channel from {{ ref('slv_web__sessions') }}

),

accounts as (

    select email, customer_key from {{ ref('slv_crm__accounts') }}

)

select
    to_number(to_char(events.event_ts, 'YYYYMMDD'))   as date_key,
    coalesce(accounts.customer_key, '-1')             as customer_key,
    events.product_id                                 as product_key,
    sessions.channel                                  as channel_key,

    events.event_id,
    events.session_id,
    events.event_ts,
    events.action,

    iff(events.action = 'view_item', 1, 0)            as is_view,
    iff(events.action = 'add_to_cart', 1, 0)          as is_add_to_cart,
    iff(events.action = 'purchase', 1, 0)             as is_purchase,
    iff(events.logged_email is null, 1, 0)            as is_anonymous,

    events._loaded_at
from events
inner join sessions on events.session_id = sessions.session_id
left join  accounts on events.logged_email = accounts.email