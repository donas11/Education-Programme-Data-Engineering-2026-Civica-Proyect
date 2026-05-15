with source as (
  select * from {{ source('bronze_raw', 'models') }}
),

normalized_model as (
  select
    *,
    {{ normalize_model_name('model_id', 'model_name') }}
  from source
)

select * from normalized_model