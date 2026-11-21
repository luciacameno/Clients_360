select
    ticket_id,
    line_number,
    product_id,
    amount_eur
from {{ ref('stg_pos__sales') }}