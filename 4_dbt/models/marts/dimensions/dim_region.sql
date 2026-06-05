{{ config(materialized='table') }}

select
    id_region,
    region AS region_nombre
from {{ ref('region') }}
