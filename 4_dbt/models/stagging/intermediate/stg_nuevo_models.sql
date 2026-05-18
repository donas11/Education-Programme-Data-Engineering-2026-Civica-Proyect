with source as (
  select * from {{ source('bronze_raw', 'models') }}
  
),

normalized_model as (
  select
    model_id as model_id_raw_name,
    {{ clean_model_name('model_id') }} as model_name_standard,
     {{ model_orden_nombre('model_id')}} as model_name_order,
        model_family as familia,
       release_date as fecha_lanzamiento 
  from source
)

select * from normalized_model