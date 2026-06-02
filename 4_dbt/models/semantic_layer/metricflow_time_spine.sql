{{ config(materialized='table') }}

select fecha as date_day
from {{ ref('dim_fecha') }}