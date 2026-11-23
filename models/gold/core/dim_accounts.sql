{#
  Una fila por cuenta del CRM, con la persona a la que pertenece y su tier.
  Sin agregar
#}
{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='account_key'
    )
}}

select
    accounts.crm_id             as account_key,
    accounts.customer_key,
    accounts.full_name,
    accounts.email,
    accounts.phone,
    tiers.tier_name,
    tiers.tier_rank,
    accounts.join_ts::date      as join_date,
    accounts._loaded_at
from {{ ref('slv_crm__accounts') }} accounts
inner join {{ ref('slv_crm__tiers') }} tiers on accounts.tier_id = tiers.tier_id

{% if is_incremental() %}
where accounts._loaded_at > (select max(existing._loaded_at) from {{ this }} as existing)
{% endif %}