{#
  Golden Record: una fila por persona, más la fila -1 "No identificada".
  Sin agregar: los datos salen de su cuenta principal (la más antigua),
  que es la que da nombre al customer_key. El tier más alto (R1b) se calcula en los marts.
#}
{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='customer_key'
    )
}}

with customers as (

    select
        customers.customer_key,
        accounts.full_name,
        accounts.email                                       as primary_email,
        accounts.join_ts::date                               as join_date,
        greatest(customers._loaded_at, accounts._loaded_at)  as _loaded_at
    from {{ ref('slv_crm__customers') }} customers
    inner join {{ ref('slv_crm__accounts') }} accounts
            on accounts.crm_id = customers.customer_key   -- la cuenta principal

)

select * from customers

{% if is_incremental() %}
where _loaded_at > (select max(existing._loaded_at) from {{ this }} as existing)
{% else %}
union all
select '-1', 'No identificada', null, null, null
{% endif %}