select
    {{ dbt_utils.generate_surrogate_key(['reason_name']) }} as return_reason_id,
    reason_name,
    reason_group
from {{ ref('return_reasons') }}