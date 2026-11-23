{#
  Una fila por PERSONA (regla R1a).
  Cuentas con el mismo teléfono limpio y el mismo nombre normalizado = misma persona.
  customer_key = crm_id de la cuenta más antigua.
#}
{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='match_key'
    )
}}

with accounts as (

    select
        crm_id,
        join_ts,
        _loaded_at,
        phone || '|' || {{ normalize_name('full_name') }} as match_key
    from {{ ref('stg_crm__accounts') }}

    {% if is_incremental() %}
    where _loaded_at > (select max(existing._loaded_at) from {{ this }} as existing)
    {% endif %}

)

select
    min_by(crm_id, join_ts) as customer_key,
    match_key,
    max(_loaded_at)         as _loaded_at
from accounts
group by match_key