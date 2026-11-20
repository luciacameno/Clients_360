with source as (

    select * from {{ source('pos', 'sales') }}

),

renamed as (

    select
        ticket_id,
        try_to_number(line_number)                                   as line_number,
        store_id,
        try_to_timestamp_ntz(sale_date, 'YYYY-MM-DD"T"HH24:MI:SS.FF6') as sale_ts,
        customer_email_input                                         as email_raw,
        {{ clean_email('customer_email_input') }}                    as email,
        customer_phone_input                                         as phone_raw,
        {{ clean_phone('customer_phone_input') }}                    as phone,
        product_id,
        try_to_number(amount, 10, 2)                                 as amount_eur,
        upper(trim(transaction_type))                                as transaction_type,
        nullif(original_ticket_id, '')                               as original_document_id,
        nullif(trim(return_reason), '')                              as return_reason,
        _loaded_at
    from source

)

select * from renamed