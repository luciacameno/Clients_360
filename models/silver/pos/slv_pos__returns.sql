{#
  Una fila por línea devuelta, con sus atributos propios (relación 1:0..1 con la línea).
  El original es un tique de tienda o un pedido online (empieza por 'ORD-'), nunca los dos.
#}
select
    ticket_id,
    line_number,
    {{ dbt_utils.generate_surrogate_key(['return_reason']) }} as return_reason_id,
    case when original_document_id not like 'ORD-%'
         then original_document_id end                        as original_ticket_id,
    case when original_document_id like 'ORD-%'
         then original_document_id end                        as original_order_id
from {{ ref('stg_pos__sales') }}
where transaction_type = 'RETURN'