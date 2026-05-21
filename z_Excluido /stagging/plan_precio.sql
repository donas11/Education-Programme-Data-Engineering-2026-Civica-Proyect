  SELECT DISTINCT
    {{ dbt_utils.generate_surrogate_key([
      'id_modelo',
      'id_region',
      'tipo_plan',
      'unidad_facturacion'
      ]) }} AS id_plan_precio,
    tipo_plan,
    unidad_facturacion,
    id_modelo,
    id_region
  FROM {{ ref('stg_planes') }}
