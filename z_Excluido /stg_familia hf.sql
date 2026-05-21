{{ config(materialized='view') }}  

union_familia AS (
  SELECT DISTINCT
    familia_nombre
  FROM  {{ ref('stg_huggingface_models') }} 
  UNION ALL
  SELECT DISTINCT
    familia_nombre
  FROM  {{ ref('stg_modelo') }} 
),

fusion_familia AS (
  SELECT DISTINCT
    familia_nombre
  FROM  union_familia
),

familia AS (
  SELECT
    {{ dbt_utils.generate_surrogate_key(['familia_nombre']) }} AS id_familia,
    familia_nombre AS nombre
  FROM fusion_familia
)

SELECT * FROM familia