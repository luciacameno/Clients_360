{#
  Cabecera del tique (2FN): tienda, fecha y clienta dependen solo de ticket_id.
  Identificación de la clienta (regla R1c):
    1. email limpio que existe en el CRM
    2. si no, teléfono limpio que pertenece a UNA sola clienta
    3. si no, sin identificar (customer_key nulo)
#}
with sales as (

    select * from {{ ref('stg_pos__sales') }}

),

headers as (

    select
        ticket_id,
        any_value(store_id)         as store_id,
        any_value(sale_ts)          as ticket_ts,
        any_value(transaction_type) as ticket_type,
        any_value(email_raw)        as email_raw,
        any_value(email)            as email,
        any_value(phone)            as phone
    from sales
    group by ticket_id

),

accounts as (

    select email, customer_key from {{ ref('slv_crm__accounts') }}

),

phone_owners as (

    select
        phone,
        count(distinct customer_key) as n_customers,
        any_value(customer_key)      as customer_key
    from {{ ref('slv_crm__accounts') }}
    group by phone

)

select
    headers.ticket_id,
    headers.store_id,
    coalesce(
        accounts.customer_key,
        case when phone_owners.n_customers = 1 then phone_owners.customer_key end
    )                                                       as customer_key,
    headers.ticket_ts,
    headers.ticket_type,
    case
        when accounts.customer_key is not null
             and headers.email_raw = headers.email          then 'email'
        when accounts.customer_key is not null              then 'email_corregido'
        when phone_owners.n_customers = 1                   then 'telefono'
        when phone_owners.n_customers > 1                   then 'telefono_compartido'
        else 'ninguno'
    end                                                     as identification_method
from headers
left join accounts     on headers.email = accounts.email
left join phone_owners on headers.phone = phone_owners.phone