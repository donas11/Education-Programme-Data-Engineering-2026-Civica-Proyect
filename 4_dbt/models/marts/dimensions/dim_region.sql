{{ config(materialized='table') }}

select
    id_region,
    region_nombre
from {{ ref('region') }}
