{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='product_key'
    )
}}

select
    products.product_id                                         as product_key,
    products.product_name,
    ranges.range_name,
    ranges.brand_name,
    products.subcategory_name,
    categories.category_name,
    products.shade,
    products.size,
    products.list_price_eur,
    products.subcategory_name in ('Foundation', 'Concealer')    as is_complexion,
    products._loaded_at
from {{ ref('slv_catalog__products') }} products
inner join {{ ref('slv_catalog__ranges') }}     ranges     on products.range_id = ranges.range_id
inner join {{ ref('slv_catalog__categories') }} categories on products.category_id = categories.category_id

{% if is_incremental() %}
where products._loaded_at > (select max(existing._loaded_at) from {{ this }} as existing)
{% endif %}