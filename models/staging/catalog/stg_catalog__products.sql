with source as (

    select * from {{ source('catalog', 'products') }}

),

renamed as (

    select
        product_id,
        trim(name)                        as product_name,
        try_to_number(price, 10, 2)       as list_price_eur,
        trim(category)                    as category_name,
        trim(subcategory)                 as subcategory_name,
        trim(brand)                       as brand_name,
        trim(product_line)                as range_name,       -- "gama" (ver fase 0)
        nullif(trim(shade), '')           as shade,
        nullif(trim(size), '')            as size,
        _loaded_at
    from source

)

select * from renamed