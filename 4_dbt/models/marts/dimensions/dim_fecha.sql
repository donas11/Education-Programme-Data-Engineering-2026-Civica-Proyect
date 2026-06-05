{{ config(materialized='table') }}

with date_spine as (
    {{ dbt_date.date_spine(
        start_date="'2020-01-01'",
        end_date="'2031-01-01'",
        datepart="day"
    ) }}
)

select
    cast(to_number(to_char(date_day, 'YYYYMMDD')) as int) as id_fecha,
    date_day as fecha_valor,
    extract(week from date_day) as semana,
    extract(month from date_day) as mes,
    extract(quarter from date_day) as trimestre,
    extract(year from date_day) as anho,
    dayname(date_day) as nombre_dia,
    monthname(date_day) as nombre_mes
from date_spine
