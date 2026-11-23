{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='crm_id'
    )
}}

with accounts as (

    select
        *,
        phone || '|' || {{ normalize_name('full_name') }} as match_key
    from {{ ref('stg_crm__accounts') }}

    {% if is_incremental() %}
    where _loaded_at > (select max(existing._loaded_at) from {{ this }} as existing)
    {% endif %}

    -- Si una cuenta llega varias veces (alta y luego un cambio), la última versión
    qualify row_number() over (partition by crm_id order by _loaded_at desc) = 1

),

customers as (

    select * from {{ ref('slv_crm__customers') }}

),

tiers as (

    select * from {{ ref('slv_crm__tiers') }}

)

select
    accounts.crm_id,
    customers.customer_key,
    accounts.full_name,
    accounts.email,
    accounts.phone,
    tiers.tier_id,
    accounts.join_ts,
    accounts._loaded_at
from accounts
inner join customers on accounts.match_key = customers.match_key
left join  tiers     on accounts.tier_name = tiers.tier_name