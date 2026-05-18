with source as (

  select *
  from {{ source('bronze_raw', 'ai_models_performance') }}

),

normalized as (

  select
    Model as model_id_raw_name,
       
    {{ remove_parentheses_content(
      clean_model_name('Model')
       ) }} as model_name_standard  



  from source

)

select * from normalized
