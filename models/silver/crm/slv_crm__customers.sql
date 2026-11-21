{#
  Una fila por PERSONA (regla R1a).
  Cuentas con el mismo teléfono limpio y el mismo nombre normalizado = misma persona.
  customer_key = crm_id de la cuenta más antigua.
#}
with accounts as (

    select
        crm_id,
        join_ts,
        phone || '|' || {{ normalize_name('full_name') }} as match_key
    from {{ ref('stg_crm__accounts') }}

)

select
    min_by(crm_id, join_ts) as customer_key,
    match_key
from accounts
group by match_key