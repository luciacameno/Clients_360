with days as (

    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2024-01-01' as date)",
        end_date="cast('2027-01-01' as date)"
    ) }}

)

select
    to_number(to_char(date_day, 'YYYYMMDD'))   as date_key,
    date_day                                   as date,
    year(date_day)                             as year,
    month(date_day)                            as month,
    to_char(date_day, 'YYYY-MM')               as year_month,
    dayofweekiso(date_day)                     as day_of_week,
    dayofweekiso(date_day) in (6, 7)           as is_weekend
from days