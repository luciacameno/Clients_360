{#
  Golden Record: una fila por persona, más la fila -1 "No identificada".
  Supervivencia del dato (R1b): tier más alto; alta, nombre y email de la cuenta más antigua.
#}
with accounts as (

    select accounts.*, tiers.tier_name, tiers.tier_rank
    from {{ ref('slv_crm__accounts') }} accounts
    inner join {{ ref('slv_crm__tiers') }} tiers on accounts.tier_id = tiers.tier_id

),

shared_phones as (

    select phone
    from accounts
    group by phone
    having count(distinct customer_key) > 1

),

customers as (

    select
        customer_key,
        min_by(full_name, join_ts)                 as full_name, --del minimo jooin_ts , el name 
        min_by(email, join_ts)                     as primary_email,
        max_by(tier_name, tier_rank)               as tier_name,
        max(tier_rank)                             as tier_rank,
        min(join_ts)::date                         as join_date,
        count(*)                                   as n_accounts,
        max(iff(phone in (select phone from shared_phones), 1, 0)) = 1
                                                   as is_shared_phone --solo para comprobnar si tiene algun shared phone 
    from accounts
    group by customer_key

)

select * from customers

union all

select '-1', 'No identificada', null, null, null, null, 0, false