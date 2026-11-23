{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='range_id'
    )
}}

with ranges as (

    select
        brand_name,
        range_name,
        max(_loaded_at) as _loaded_at
    from {{ ref('stg_catalog__products') }}

    {% if is_incremental() %}
    where _loaded_at > (select max(existing._loaded_at) from {{ this }} as existing)
    {% endif %}

    group by brand_name, range_name

)

select
    {{ dbt_utils.generate_surrogate_key(['brand_name', 'range_name']) }} as range_id,
    range_name,
    brand_name,
    _loaded_at
from ranges