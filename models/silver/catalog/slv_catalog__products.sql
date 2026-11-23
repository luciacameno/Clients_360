{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='product_id'
    )
}}

select
    product_id,
    product_name,
    {{ dbt_utils.generate_surrogate_key(['brand_name', 'range_name']) }} as range_id,
    {{ dbt_utils.generate_surrogate_key(['category_name']) }}           as category_id,
    subcategory_name,
    shade,
    size,
    list_price_eur,
    _loaded_at
from {{ ref('stg_catalog__products') }}

{% if is_incremental() %}
where _loaded_at > (select max(existing._loaded_at) from {{ this }} as existing)
{% endif %}

-- Si Bronze acumula cargas completas, nos quedamos con la versión más reciente
qualify row_number() over (partition by product_id order by _loaded_at desc) = 1