{{ config(materialized='view') }}

SELECT
  id_model as id_modelo,
  nombre_comercial,
  p.id_proveedor,
  f.id_familia,
  context_window,
  multimodal,
  opensource,
  fecha_lanzamiento
FROM {{ ref('stg_modelo') }} md
left join {{ ref('proveedor') }} p
  on upper(trim({{remove_parentheses_content('md.provider')}})) = p.proveedor
left join {{ ref('familia') }} f
  on upper(trim(f.nombre)) = upper(trim(md.familia_nombre))
