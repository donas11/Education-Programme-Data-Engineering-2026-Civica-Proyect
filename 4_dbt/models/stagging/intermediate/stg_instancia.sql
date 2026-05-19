{{ config(materialized='view') }}  

with fusion_prooveedor AS (
  SELECT DISTINCT
    proveedor
  FROM {{ source('bronze_raw', 'proveedores') }}
  UNION ALL
  SELECT DISTINCT
    proveedor
  FROM {{ source('bronze_raw', 'proveedores_servidor') }}
),

proveedor AS (
  SELECT DISTINCT
    provider AS proveedor,
    "INSTANCIA"    AS tipo_proveedor
  FROM fusion_prooveedor
)

SELECT * FROM proveedor
