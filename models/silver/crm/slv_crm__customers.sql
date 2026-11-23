{#
  Una fila por PERSONA (regla R1a).
  Cuentas con el mismo teléfono limpio y el mismo nombre normalizado = misma persona.
  customer_key = crm_id de la cuenta más antigua.

  Incremental: las cuentas nuevas o modificadas solo dicen QUÉ personas recalcular;
  cada persona se recalcula con TODAS sus cuentas (si no, una cuenta nueva
  cambiaría el customer_key de una clienta que ya existe).
#}
{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='match_key'
    )
}}

with all_accounts as (

    select
        crm_id,
        join_ts,
        _loaded_at,
        phone || '|' || {{ normalize_name('full_name') }} as match_key
    from {{ ref('stg_crm__accounts') }}
    -- Bronze acumula versiones de una misma cuenta: nos quedamos con la última
    qualify row_number() over (partition by crm_id order by _loaded_at desc) = 1

),

accounts as (

    select * from all_accounts

    {% if is_incremental() %}
    where match_key in (
        select match_key
        from all_accounts
        where _loaded_at > (select max(existing._loaded_at) from {{ this }} as existing)
    )
    {% endif %}

)

select
    min_by(crm_id, join_ts) as customer_key,
    match_key,
    max(_loaded_at)         as _loaded_at
from accounts
group by match_key