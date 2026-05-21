{{ config(materialized='table') }}

select
    id_region,
    region
from {{ ref('region') }}
