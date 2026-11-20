select
    {{ dbt_utils.generate_surrogate_key(['tier_name']) }} as tier_id,
    tier_name,
    tier_rank
from {{ ref('tiers') }}