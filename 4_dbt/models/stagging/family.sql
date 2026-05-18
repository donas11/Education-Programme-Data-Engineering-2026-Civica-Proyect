{{ config(
  schema = 'SILVER',
  materialized = 'view'
) }}

-- 1) Traer los nombres de modelo de cada fuente con la misma columna

WITH all_models AS (

  SELECT
    model_name as modelo,
    model_family as familia
  FROM {{ source('bronze_raw', 'models') }}

  UNION ALL

  SELECT
    model_id as modelo,
    NULL as familia
 FROM {{ source('bronze_raw', 'nuevo_openrouter_modelos') }}

  UNION ALL

  SELECT
    model as modelo,
    NULL as familia
   FROM {{ source('bronze_raw', 'llm_model_comparison_2026') }}

   UNION ALL

  SELECT
    model as modelo,
    family as familia
   FROM {{ source('bronze_raw', 'llm_complete_dataset') }}


    UNION ALL

  SELECT
    Model as modelo,
    NULL as familia
   from {{ source('bronze_raw', 'ai_models_performance') }}
),

-- 2) Obtener la primera palabra (= familia) y quitar duplicados

fusion_familia AS (
  SELECT DISTINCT
    REGEXP_SUBSTR(model_name, '^[^ ]+') AS familia_nombre
  FROM all_models
  WHERE model_name IS NOT NULL
),

-- 3) Generar id_familia hash

familia AS (
  SELECT
    {{ dbt_utils.generate_surrogate_key(['familia_nombre']) }} AS id_familia,
    familia_nombre AS nombre
  FROM fusion_familia
)

SELECT * FROM familia;