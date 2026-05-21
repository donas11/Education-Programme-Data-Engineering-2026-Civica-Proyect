{{ config(materialized='view') }}

with fusion_familia AS (
  SELECT DISTINCT
    familia_nombre
  FROM {{ ref('stg_modelo_union') }}
),

familia AS (
  SELECT
    {{ dbt_utils.generate_surrogate_key(['familia_nombre']) }} AS id_familia,
    familia_nombre AS nombre
  FROM fusion_familia
)

SELECT * FROM familia
