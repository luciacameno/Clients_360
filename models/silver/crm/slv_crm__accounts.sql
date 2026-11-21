with accounts as (

    select
        *,
        phone || '|' || {{ normalize_name('full_name') }} as match_key
    from {{ ref('stg_crm__accounts') }}

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
    accounts.join_ts
from accounts
inner join customers on accounts.match_key = customers.match_key
left join  tiers     on accounts.tier_name = tiers.tier_name