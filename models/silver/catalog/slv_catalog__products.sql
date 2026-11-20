select
    product_id,
    product_name,
    {{ dbt_utils.generate_surrogate_key(['brand_name', 'range_name']) }} as range_id,
    {{ dbt_utils.generate_surrogate_key(['category_name']) }}           as category_id,
    subcategory_name,
    shade,
    size,
    list_price_eur
from {{ ref('stg_catalog__products') }}