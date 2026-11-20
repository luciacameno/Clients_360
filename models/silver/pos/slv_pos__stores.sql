select
    store_id,
    store_name,
    city
from {{ ref('stores') }}