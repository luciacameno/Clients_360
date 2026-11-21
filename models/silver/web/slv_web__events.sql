{#
  Registro de lo que pasó en la web. Cuelga solo de la sesión.
  product_id, logged_email y order_id son ATRIBUTOS, sin relación declarada
  (corrección de Jairo ): el cruce con el catálogo y con las clientas se hace en gold.
#}
select
    event_id,
    session_id,
    event_ts,
    action,
    product_id,
    user_email as logged_email,
    order_id
from {{ ref('stg_web__events') }}