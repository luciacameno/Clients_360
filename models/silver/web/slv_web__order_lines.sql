select
    order_id,
    product_id,
    unit_price_eur
from {{ ref('stg_web__events') }}
where action = 'purchase'