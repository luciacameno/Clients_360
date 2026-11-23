{{
       config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key=['order_id','product_id']
    )
}}


select
    order_id,
    product_id,
    unit_price_eur,
    _loaded_at
from {{ ref('stg_web__events') }}
where action = 'purchase'

{% if is_incremental() %}
and _loaded_at > (select max(_loaded_at) from {{ this }})
{% endif %}