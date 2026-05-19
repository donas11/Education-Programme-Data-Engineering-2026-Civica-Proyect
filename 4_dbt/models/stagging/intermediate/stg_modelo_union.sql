{{ config(materialized='view') }}  


union_familia AS (
  SELECT 
    id_model,
    nombre_comercial,
    provider,
    familia_nombre,
    context_window,
    multimodal,
    opensource,
    fecha_lanzamiento    
  FROM  {{ ref('stg_modelo') }} 
  UNION ALL
  SELECT 
    id_model,
    nombre_comercial,
    provider,
    familia_nombre,
    context_window,
    multimodal,
    opensource,
    fecha_lanzamiento 
  FROM  {{ ref('stg_huggingface_models') }} 
)

