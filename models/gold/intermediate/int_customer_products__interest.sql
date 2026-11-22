{#
  R6 · Temperatura del interés por clienta y producto:
  puntuación = suma de peso(acción) x 0,5 ^ (días desde la interacción / vida media).
  Solo productos que la clienta no ha comprado ni devuelto, y solo los últimos N días.
#}
with reference as (

    select coalesce(
        try_to_timestamp_ntz('{{ var("reference_date") }}'),
        (select max(event_ts) from {{ ref('fct_web_events') }})
    ) as reference_ts

),

interactions as (

    select customer_key, product_key, event_ts, action
    from {{ ref('fct_web_events') }}, reference
    where customer_key <> '-1'
      and action in ('view_item', 'add_to_cart')
      and event_ts <= reference.reference_ts
      and event_ts >= dateadd(day, -{{ var('interest_lookback_days') }}, reference.reference_ts)

),

already_bought_or_returned as (

    select distinct customer_key, product_key
    from {{ ref('fct_sales') }}
    where customer_key <> '-1'

),

scored as (

    select
        interactions.customer_key,
        interactions.product_key,
        sum(
            iff(interactions.action = 'add_to_cart', --iff (condicion, si_siii ,si_no ) es el if de sown 
                {{ var('interest_weight_cart') }}, {{ var('interest_weight_view') }}) --cart = 3 , view = 1 
            * power(0.5,
                datediff('second', interactions.event_ts, reference.reference_ts) / 86400 --/ 86400: lo pasa a días con decimales (un día tiene 86.400 segundos). Se hace así porque datediff('day', ...) daría días enteros, y un evento de hace 36 horas contaría como 1 día o 2 según la hora.
                / {{ var('interest_half_life_days') }}) --/vida_media
        )                                      as interest_score,
        count(*)                               as n_interactions,
        max(interactions.event_ts)             as last_interaction_ts
    from interactions, reference
    group by interactions.customer_key, interactions.product_key

)

select
    scored.*,
    case
        when interest_score >= {{ var('interest_hot_threshold') }}  then 'caliente'
        when interest_score >= {{ var('interest_warm_threshold') }} then 'templado'
        else 'frio'
    end                                        as temperature
from scored
left join already_bought_or_returned done
       on scored.customer_key = done.customer_key
      and scored.product_key = done.product_key
where done.customer_key is null  --se queda con las filas de scored que no aparecen en already_bought_or_returned. En este modelo sirve para quitar los productos que la clienta ya compró o devolvió.