with source as (

  select *
  from {{ source('bronze_raw', 'huggingface_models') }}

),

normalized as (

  select
    name as model_id_raw_name,
    
     {{ remove_parentheses_content(
      extract_canonical_model_name('name', 2)
       ) }} as model_name_standard   
    
  from source

)

select * from normalized
