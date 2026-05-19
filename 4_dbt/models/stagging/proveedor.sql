SELECT
    {{ dbt_utils.generate_surrogate_key(['provider']) }} AS id_proveedor,
    provider AS proveedor,
    "API"    AS tipo_proveedor
  FROM {{ ref('stg_proveedor') }}



SELECT proveedor 
 WHEN 

  SELECT DISTINCT
    provider AS proveedor,
    "INSTANCIA"    AS tipo_proveedor
  FROM {{ ref('stg_instancia') }}