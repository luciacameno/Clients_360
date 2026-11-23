-- R7: un carrito abandonado NO puede tener una compra posterior del mismo producto
-- en ningún canal (tienda u online). Si sale alguna fila, la regla está rota.
select
    signals.customer_key,
    signals.product_key,
    signals.last_interaction_ts as last_cart_ts,
    sales.sale_ts,
    sales.channel_key
from {{ ref('agg_clienteling_signals') }} signals
inner join {{ ref('fct_sales') }} sales
        on signals.customer_key = sales.customer_key
       and signals.product_key = sales.product_key
where signals.signal_type = 'carrito'
  and sales.is_sale = 1
  and sales.sale_ts > signals.last_interaction_ts