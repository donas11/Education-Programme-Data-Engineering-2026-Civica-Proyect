
-- Use the `ref` function to select from other models

with src as (
    select *
    from {{ source('bronze_raw','benchmarks') }}
)

select
    cast(model_id as varchar)       as model_id,
    cast(benchmark_name as varchar) as benchmark_name,
    cast(score as float)            as score,
    cast(fecha as timestamp)        as fecha
from src