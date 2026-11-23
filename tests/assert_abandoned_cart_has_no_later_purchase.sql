-- R7: un carrito abandonado NO puede tener una compra posterior del mismo producto
-- en ningún canal (tienda u online). Si sale alguna fila, la regla está rota.
select
    carts.customer_key,
    carts.product_key,
    carts.last_cart_ts,
    sales.sale_ts,
    sales.channel_key
from {{ ref('int_customer_products__abandoned_carts') }} carts
inner join {{ ref('fct_sales') }} sales
        on carts.customer_key = sales.customer_key
       and carts.product_key = sales.product_key
where sales.is_sale = 1
  and sales.sale_ts > carts.last_cart_ts