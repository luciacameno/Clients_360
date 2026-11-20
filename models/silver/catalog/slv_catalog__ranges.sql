with ranges as (

    select distinct brand_name, range_name
    from {{ ref('stg_catalog__products') }}

)

select
    {{ dbt_utils.generate_surrogate_key(['brand_name', 'range_name']) }} as range_id,
    range_name,
    brand_name
from ranges