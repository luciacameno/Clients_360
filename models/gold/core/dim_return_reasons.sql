select return_reason_id as return_reason_key, reason_name, reason_group
from {{ ref('slv_pos__return_reasons') }}

union all

select '-1', 'Sin motivo (venta)', null