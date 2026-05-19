{{ config(materialized='view') }}  

fusion_prooveedor AS (
  SELECT DISTINCT
    provider
  FROM  from {{ ref('stg_modelo_union') }}
),



proveedor AS (
  SELECT
    {{ dbt_utils.generate_surrogate_key(['provider']) }} AS id_proveedor,
    provider AS proveedor
    "API"    AS tipo_proveedor
  FROM fusion_prooveedor
)

SELECT * FROM proveedor
