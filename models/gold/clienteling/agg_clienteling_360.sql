{#
  Una fila por clienta: quién es, cuánto ha gastado, su tono y sus avisos.
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

spend as (

    select
        customer_key,
        sum(amount_eur)                                              as ltv_total_eur,
        sum(iff(channel_key = 'tienda', amount_eur, 0))              as ltv_store_eur,
        sum(iff(channel_key in ('web', 'app'), amount_eur, 0))       as ltv_online_eur,
        sum(is_return)                                               as n_returns
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

interest as (

    select customer_key, count_if(temperature = 'caliente') as n_hot_interests
    from {{ ref('int_customer_products__interest') }}
    group by customer_key

),

carts as (

    select customer_key, count(*) as n_abandoned_carts
    from {{ ref('int_customer_products__abandoned_carts') }}
    group by customer_key

)

select
    customers.customer_key,
    customers.full_name,
    customers.primary_email,
    customers.tier_name,
    customers.join_date,
    datediff('month', customers.join_date, reference.reference_ts)  as months_since_join,
    coalesce(stores.store_name, 'Solo online')                      as home_store,
    customers.n_accounts,
    coalesce(spend.ltv_total_eur, 0)                                as ltv_total_eur,
    coalesce(spend.ltv_store_eur, 0)                                as ltv_store_eur,
    coalesce(spend.ltv_online_eur, 0)                               as ltv_online_eur,
    shade.confirmed_shade,
    shade.discarded_shades,
    coalesce(interest.n_hot_interests, 0)                           as n_hot_interests,
    coalesce(carts.n_abandoned_carts, 0)                            as n_abandoned_carts,
    coalesce(spend.n_returns, 0)                                    as n_returns
from customers
cross join reference
left join spend      on customers.customer_key = spend.customer_key
left join home_store on customers.customer_key = home_store.customer_key
left join {{ ref('dim_stores') }} stores on home_store.store_key = stores.store_key
left join {{ ref('int_customers__shade') }} shade on customers.customer_key = shade.customer_key
left join interest   on customers.customer_key = interest.customer_key
left join carts      on customers.customer_key = carts.customer_key