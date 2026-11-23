{#
  La ficha del iPad: una fila por clienta.
  Aquí se agrega (en core no): tier superviviente (R1b), nº de cuentas, LTV (R4),
  tienda habitual (R2), pasaporte de tono (R9) y los contadores de avisos.
#}
with reference as (

    select coalesce(
        try_to_timestamp_ntz('{{ var("reference_date") }}'),
        (select max(event_ts) from {{ ref('fct_web_events') }})
    ) as reference_ts

),

customers as (

    select * from {{ ref('dim_customers') }}
    where customer_key <> '-1'

),

accounts as (  -- R1b: el tier más alto de todas sus cuentas

    select
        customer_key,
        count(*)                                                as n_accounts,
        max_by(tier_name, tier_rank)                            as tier_name,
        max(tier_rank)                                          as tier_rank,
        max(iff(account_key = customer_key, tier_rank, null))   as principal_tier_rank
    from {{ ref('dim_accounts') }}
    group by customer_key

),

spend as (  -- R4: LTV neto, por canal

    select
        customer_key,
        sum(amount_eur)                                         as ltv_total_eur,
        sum(iff(channel_key = 'tienda', amount_eur, 0))         as ltv_store_eur,
        sum(iff(channel_key in ('web', 'app'), amount_eur, 0))  as ltv_online_eur,
        sum(is_return)                                          as n_returns,
        count_if(is_sale = 1 and channel_key = 'tienda') > 0
            and count_if(is_sale = 1 and channel_key in ('web', 'app')) > 0
                                                                as is_omnichannel
    from {{ ref('fct_sales') }}
    group by customer_key

),

home_store as (  -- R2: tienda con más tiques de venta; empate, la más reciente

    select customer_key, store_key
    from (
        select customer_key, store_key,
               count(distinct document_id) as n_tickets, max(sale_ts) as last_ts
        from {{ ref('fct_sales') }}
        where channel_key = 'tienda' and is_sale = 1
        group by customer_key, store_key
    )
    qualify row_number() over (partition by customer_key order by n_tickets desc, last_ts desc) = 1

),

-- ── R9 · Pasaporte de tono (solo bases y correctores) ────────────────────
complexion_sales as (

    select sales.customer_key, sales.product_key, sales.sale_ts, sales.is_return,
           products.shade, products.range_name, reasons.reason_group
    from {{ ref('fct_sales') }} sales
    inner join {{ ref('dim_products') }}       products on sales.product_key = products.product_key
    inner join {{ ref('dim_return_reasons') }} reasons  on sales.return_reason_key = reasons.return_reason_key
    where sales.customer_key <> '-1' and products.is_complexion

),

returned as (

    select distinct customer_key, product_key
    from complexion_sales
    where is_return = 1

),

shade_confirmed as (  -- el último comprado y NO devuelto

    select
        complexion_sales.customer_key,
        max_by(complexion_sales.shade, complexion_sales.sale_ts)      as confirmed_shade,
        max_by(complexion_sales.range_name, complexion_sales.sale_ts) as confirmed_range
    from complexion_sales
    left join returned
           on complexion_sales.customer_key = returned.customer_key
          and complexion_sales.product_key = returned.product_key
    where complexion_sales.is_return = 0 and returned.customer_key is null
    group by complexion_sales.customer_key

),

shade_discarded as (  -- los devueltos por un motivo de tono

    select customer_key,
           listagg(distinct shade, ', ') within group (order by shade) as discarded_shades
    from complexion_sales
    where is_return = 1 and reason_group = 'tono'
    group by customer_key

),

signal_counts as (

    select
        customer_key,
        count_if(signal_type = 'interes' and temperature = 'caliente')  as n_hot_interests,
        count_if(signal_type = 'carrito')                               as n_abandoned_carts
    from {{ ref('agg_clienteling_signals') }}
    group by customer_key

)

select
    customers.customer_key,
    customers.full_name,
    customers.primary_email,
    accounts.tier_name,
    accounts.tier_rank > accounts.principal_tier_rank                as is_tier_upgraded_by_merge,
    customers.join_date,
    datediff('month', customers.join_date, reference.reference_ts)  as months_since_join,
    coalesce(stores.store_name, 'Solo online')                      as home_store,
    accounts.n_accounts,
    coalesce(spend.ltv_total_eur, 0)                                as ltv_total_eur,
    coalesce(spend.ltv_store_eur, 0)                                as ltv_store_eur,
    coalesce(spend.ltv_online_eur, 0)                               as ltv_online_eur,
    coalesce(spend.is_omnichannel, false)                           as is_omnichannel,
    shade_confirmed.confirmed_shade,
    shade_confirmed.confirmed_range,
    shade_discarded.discarded_shades,
    coalesce(signal_counts.n_hot_interests, 0)                      as n_hot_interests,
    coalesce(signal_counts.n_abandoned_carts, 0)                    as n_abandoned_carts,
    coalesce(spend.n_returns, 0)                                    as n_returns
from customers
cross join reference
left join accounts        on customers.customer_key = accounts.customer_key
left join spend           on customers.customer_key = spend.customer_key
left join home_store      on customers.customer_key = home_store.customer_key
left join {{ ref('dim_stores') }} stores on home_store.store_key = stores.store_key
left join shade_confirmed on customers.customer_key = shade_confirmed.customer_key
left join shade_discarded on customers.customer_key = shade_discarded.customer_key
left join signal_counts   on customers.customer_key = signal_counts.customer_key