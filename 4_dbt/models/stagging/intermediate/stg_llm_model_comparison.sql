with source as (

  select *
  from {{ source('bronze_raw', 'llm_model_comparison_2026') }}

),

normalized as (

  select
    model as model_id_raw_name,
       
    {{ remove_parentheses_content(
      clean_model_name('model')
       ) }} as model_name_standard  



  from source

)

select * from normalized
