{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='category_id'
    )
}}

with categories as (

    select
        category_name,
        max(_loaded_at) as _loaded_at
    from {{ ref('stg_catalog__products') }}

    {% if is_incremental() %}
    where _loaded_at > (select max(existing._loaded_at) from {{ this }} as existing)
    {% endif %}

    group by category_name

)

select
    {{ dbt_utils.generate_surrogate_key(['category_name']) }} as category_id,
    category_name,
    _loaded_at
from categories