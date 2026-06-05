{{ config(materialized='table') }}

select fecha_valor as date_day
from {{ ref('dim_fecha') }}