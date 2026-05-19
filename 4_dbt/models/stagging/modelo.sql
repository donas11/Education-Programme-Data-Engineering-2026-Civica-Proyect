{{ config(materialized='view') }}  


modelo AS (
  SELECT 
    id_model,
    nombre_comercial,
    p.id_proveedor,
    f.id_familia,
    context_window,
    multimodal,
    opensource,
    fecha_lanzamiento    
  FROM  {{ ref('stg_model_union') }}  md
  left join {{ ref('proveedor') }} p
    on p.provider = md.provider
  left join {{ ref('familia') }} f
    on f.familia_nombre = md.familia_nombre
)

select * from modelo