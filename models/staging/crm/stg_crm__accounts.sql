with source as (

    select * from {{ source('crm', 'loyalty') }}

),

renamed as (

    select
        crm_id,
        trim(full_name)                                              as full_name,
        email                                                        as email_raw,
        {{ clean_email('email') }}                                   as email,
        {{ clean_phone('phone') }}                                   as phone,
        trim(tier)                                                   as tier_name,
        try_to_timestamp_ntz(join_date, 'YYYY-MM-DD"T"HH24:MI:SS.FF6') as join_ts,
        _loaded_at
    from source

)

select * from renamed