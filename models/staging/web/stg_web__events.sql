with source as (

    select * from {{ source('web', 'events_raw') }}

),

flattened as (

    select
        raw:event_id::varchar                                        as event_id,
        raw:session_id::varchar                                      as session_id,
        try_to_timestamp_ntz(raw:timestamp::varchar, 'YYYY-MM-DD"T"HH24:MI:SS.FF6') as event_ts,
        raw:cookie_id::varchar                                       as cookie_id,
        {{ clean_email("raw:user_email::varchar") }}                 as user_email,
        raw:action::varchar                                          as action,
        raw:product_id::varchar                                      as product_id,

        -- objeto context{}: dispositivo y origen de la visita
        raw:context:channel::varchar                                 as channel,
        raw:context:device_type::varchar                             as device_type,
        raw:context:os::varchar                                      as os,
        raw:context:utm_source::varchar                              as utm_source,

        -- objeto order{}: solo existe en los eventos 'purchase'
        raw:order:order_id::varchar                                  as order_id,
        raw:order:unit_price::number(10, 2)                          as unit_price_eur,
        raw:order:currency::varchar                                  as currency,

        _source_file,
        _loaded_at
    from source

)

select * from flattened