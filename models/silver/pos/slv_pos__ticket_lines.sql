{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key=['ticket_id', 'line_number']
    )
}}


select
    ticket_id,
    line_number,
    product_id,
    amount_eur,
    _loaded_at
from {{ ref('stg_pos__sales') }}


{% if is_incremental() %}
where _loaded_at > (select max(_loaded_at) from {{ this }})
{% endif %}