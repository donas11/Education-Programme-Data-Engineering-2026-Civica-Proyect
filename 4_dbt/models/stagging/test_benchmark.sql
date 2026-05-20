{{ config(
  materialized = 'view'
) }}

with src as (
  select 
    model_id,	
    benchmark_id,	
    {{ model_orden_nombre('model_id')}} as model_name_order,
    score	as puntuacion,
    evaluation_date	 as fecha
  from {{source('bronze_raw', 'benchmark_scores') }}
)

SELECT
  {{ dbt_utils.generate_surrogate_key(['benchmark_id','model_id','puntuacion','fecha']) }} AS id_test,
  {{ dbt_utils.generate_surrogate_key(['benchmark_id']) }} AS id_benchmark,
   mid.id_model,   	
  benchmark_id,	
  puntuacion,
  fecha
FROM src s
LEFT JOIN {{ref('stg_model_union_ids')}} mid
    ON mid.model_name_order=s.model_name_order

