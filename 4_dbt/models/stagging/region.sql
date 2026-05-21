{{ config(materialized='view') }}

with region AS (
  SELECT DISTINCT
    {{ dbt_utils.generate_surrogate_key(['region']) }} AS id_region,
    region AS region
  from {{ source('bronze_raw', 'seed_region') }}
)

SELECT * FROM region
