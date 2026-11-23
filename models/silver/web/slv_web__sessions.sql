{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='session_id'
    )
}}

select
    session_id,
    any_value(cookie_id)   as cookie_id,
    any_value(channel)     as channel,
    any_value(device_type) as device_type,
    any_value(os)          as os,
    any_value(utm_source)  as utm_source,
    max(_loaded_at)        as _loaded_at
from {{ ref('stg_web__events') }}

{% if is_incremental() %}
-- Las sesiones que han recibido algún evento nuevo, recalculadas con TODOS sus eventos
where session_id in (
    select session_id
    from {{ ref('stg_web__events') }}
    where _loaded_at > (select max(_loaded_at) from {{ this }})
)
{% endif %}

group by session_id