with source as (

  select *
  from {{ source('bronze_raw', 'new_nuevo_openrouter_modelos') }}

),

normalized as (

  select
    model_id as model_id_raw_name,    
     {{ remove_parentheses_content(
      extract_canonical_model_name('model_id', 2)
       ) }} as model_name_standard,   
    {{ model_orden_nombre(remove_parentheses_content(
      extract_canonical_model_name('model_id', 2)
       ))}} as model_name_order
  from source

)

select * from normalized
