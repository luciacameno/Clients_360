select
    session_id,
    any_value(cookie_id)   as cookie_id,
    any_value(channel)     as channel,
    any_value(device_type) as device_type,
    any_value(os)          as os,
    any_value(utm_source)  as utm_source
from {{ ref('stg_web__events') }}
group by session_id