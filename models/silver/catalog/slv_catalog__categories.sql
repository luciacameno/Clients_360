with categories as (

    select distinct category_name
    from {{ ref('stg_catalog__products') }}

)

select
    {{ dbt_utils.generate_surrogate_key(['category_name']) }} as category_id,
    category_name
from categories