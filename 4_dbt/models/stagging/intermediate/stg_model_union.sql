with unioned as (

  select distinct
    model_id_raw_name,
    model_name_standard
  from {{ ref('stg_nuevo_models') }}

  union all

  select distinct
    model_id_raw_name,
    model_name_standard
  from {{ ref('stg_nuevo_openroute') }}

--   union all

--   select distinct
--     model_id_raw_name,
--     model_name_standard
--   from {{ ref('stg_huggingface_models') }}

  -- etc. para ai_models_performance, llm_model_comparison_2026...
  union all

   select distinct
    model_id_raw_name,
    model_name_standard
  from {{ ref('stg_llm_model_comparison') }}
     
     union all

   select distinct
    model_id_raw_name,
    model_name_standard
  from {{ ref('stg_ai_models_performance') }}


     
     


),

dedup as (
  select distinct
    model_id_raw_name,
    model_name_standard
  from unioned
)


select * from dedup