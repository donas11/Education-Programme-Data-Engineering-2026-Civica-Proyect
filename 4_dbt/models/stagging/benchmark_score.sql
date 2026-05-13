
/*
    Welcome to your first dbt model!
    Did you know that you can also configure models directly within SQL files?
    This will override configurations stated in dbt_project.yml

    Try changing "table" to "view" below
*/

with src as (
    select *
    from {{source('bronze_raw', 'benchmark_scores') }}
)

select
    cast(model_id as varchar)       as model_id,
    cast(benchmark_name as varchar) as benchmark_name,
    cast(score as float)            as score,
    cast(fecha as timestamp)        as fecha
from src

/*
    Uncomment the line below to remove records with null `id` values
*/

-- where id is not null
