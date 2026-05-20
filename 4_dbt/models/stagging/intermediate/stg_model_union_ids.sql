{{ config(materialized='view') }}
with unioned as (

  select distinct
    model_id_raw_name,
    model_name_standard,
    model_name_order
  from {{ ref('stg_nuevo_models') }}

  union all

  select distinct
    model_id_raw_name,
    model_name_standard,
    model_name_order
  from {{ ref('stg_nuevo_openroute') }}

  union all

  select distinct
    model_id_raw_name,
    model_name_standard,
    model_name_order
  from {{ ref('stg_new_nuevo_openroute') }}


  -- union all

  -- select distinct
  --   model_id_raw_name,
  --   model_name_standard,
  --   model_name_order
  -- from {{ ref('stg_huggingface_models') }}

 
  union all

   select distinct
    model_id_raw_name,
    model_name_standard,
    model_name_order
  from {{ ref('stg_llm_model_comparison') }}
     
     union all

   select distinct
    model_id_raw_name,
    model_name_standard,
    model_name_order
  from {{ ref('stg_ai_models_performance') }}

union all

   select 
    model_id_raw_name,
    model_name_standard,
    model_name_order
  from {{ ref('stg_llm_complete_dataset') }}
     
     


),

conexion as (
  select distinct
    model_name_standard,
    model_name_order
  from unioned
),

conexion_ids as (
  select distinct
    model_name_order    
  from conexion
),

model_id_created as( 
select distinct
{{ dbt_utils.generate_surrogate_key(['model_name_order']) }} AS id_model,
  model_name_order 
from conexion_ids
) 




select mid.id_model as id_model,
    model_id_raw_name,
    model_name_standard,
    mid.model_name_order
from model_id_created mid 
  join unioned un 
    on mid.model_name_order=un.model_name_order