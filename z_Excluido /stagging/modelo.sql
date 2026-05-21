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
  FROM  {{ ref('stg_modelo') }}  md
  left join {{ ref('stg_proveedor') }} p
    on p.proveedor = md.provider
  left join {{ ref('familia') }} f
    on f.nombre = md.familia_nombre
