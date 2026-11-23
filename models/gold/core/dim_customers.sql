{#
  Golden Record: una fila por persona, más la fila -1 "No identificada".
  Supervivencia del dato (R1b): tier más alto; alta, nombre y email de la cuenta más antigua.

  Incremental: se recalculan las clientas con alguna cuenta nueva o modificada,
  y las que comparten teléfono con ellas (su is_shared_phone puede cambiar).
#}
{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='customer_key'
    )
}}

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

{% if is_incremental() %}
changed_accounts as (

    select customer_key, phone
    from accounts
    where _loaded_at > (select max(existing._loaded_at) from {{ this }} as existing)

),

affected_customers as (

    select customer_key from changed_accounts
    union
    select customer_key from accounts
    where phone in (select phone from changed_accounts)

),
{% endif %}

customers as (

    select
        customer_key,
        min_by(full_name, join_ts)                 as full_name,
        min_by(email, join_ts)                     as primary_email,
        max_by(tier_name, tier_rank)               as tier_name,
        max(tier_rank)                             as tier_rank,
        min(join_ts)::date                         as join_date,
        count(*)                                   as n_accounts,
        max(iff(phone in (select phone from shared_phones), 1, 0)) = 1
                                                   as is_shared_phone,
        max(_loaded_at)                            as _loaded_at
    from accounts

    {% if is_incremental() %}
    where customer_key in (select customer_key from affected_customers)
    {% endif %}

    group by customer_key

)

select * from customers

{% if not is_incremental() %}
-- La fila -1 solo se inserta al construir la tabla desde cero; después ya existe
union all
select '-1', 'No identificada', null, null, null, null, 0, false, null
{% endif %}