with source as (
  select * from {{ source('bronze_raw', 'llm_complete_dataset') }}
  
),

normalized_model as (
  select
    model_name as model_id_raw_name,
    {{ clean_model_name('model_name') }} as model_name_standard,
     {{ model_orden_nombre('model_name')}} as model_name_order
       
  from source
)

select * from normalized_model