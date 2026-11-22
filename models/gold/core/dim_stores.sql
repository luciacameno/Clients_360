select store_id as store_key, store_name, city, false as is_online
from {{ ref('slv_pos__stores') }}

union all

select 'ONLINE', 'Tienda online', null, true