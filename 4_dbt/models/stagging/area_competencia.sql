{{ config(materialized='view') }}

WITH base AS (
  SELECT DISTINCT
    category AS area_competencia
  from {{ source('bronze_raw', 'benchmarks') }}
),

final AS (
  SELECT
    {{ dbt_utils.generate_surrogate_key(['area_competencia']) }} AS id_area_competencia,
    area_competencia
  FROM base
)

SELECT * FROM final
