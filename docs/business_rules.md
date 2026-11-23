{% docs interest_score %}
**Regla R6 · Temperatura del interés.**
Suma de cada interacción web ponderada por tipo (ver producto = 1, añadir al carrito = 3)
y por antigüedad: una interacción pierde la mitad de su valor cada 14 días.
- Caliente: 3 o más
- Templado: entre 1 y 3
- Frío: menos de 1
Solo cuenta los últimos 180 días y los productos que la clienta no ha comprado ni devuelto.
{% enddocs %}

{% docs abandoned_cart %}
**Regla R7 · Carrito abandonado.**
Último `add_to_cart` de una clienta y producto sin ninguna compra posterior de ese producto
en ningún canal (tienda u online), en los últimos 90 días.
{% enddocs %}

{% docs recommendation_score %}
**Regla R10 · Puntuación de recomendación.**
Base por motivo: carrito de 14 días o menos = 90, carrito de 15 a 90 días = 70,
interés caliente = 80, tono = 60, interés templado = 40.
+10 por cada motivo extra del mismo producto. Como mucho uno por subcategoría.
{% enddocs %}