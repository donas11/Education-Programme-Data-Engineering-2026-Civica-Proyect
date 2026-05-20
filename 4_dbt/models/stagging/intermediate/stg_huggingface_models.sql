{{ config(materialized='view') }}
with source as (

  select *
  from {{ source('bronze_raw', 'huggingface_models') }}

),

normalized as (
  select 
    {{ dbt_utils.generate_surrogate_key(['slug','name'])}} as id_model,
    {{extract_canonical_model_name('name',2)}} as nombre_comercial,
    {{extract_canonical_model_name('name',1)}}       as provider,
    slug as familia_nombre,
    null::int        as context_window,
    multimodal as multimodal,
    open_source as opensource,
    created_At as fecha_lanzamiento 
        
  from source

)

select * from normalized
