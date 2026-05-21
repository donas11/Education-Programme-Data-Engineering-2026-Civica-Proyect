{{ config(
    materialized = 'incremental',
    unique_key = 'id_test',
    on_schema_change = 'append_new_columns'
) }}

with src as (
  select
    model_id,
    benchmark_id,
    {{ model_orden_nombre('model_id')}} as model_name_order,
    score as puntuacion,
    evaluation_date as fecha
  from {{ source('bronze_raw', 'benchmark_scores') }}
),

deduped as (
  select *,
    row_number() over (partition by benchmark_id, model_id, fecha order by puntuacion desc) as rn
  from src
)

SELECT
  {{ dbt_utils.generate_surrogate_key(['benchmark_id','model_id','fecha']) }} AS id_test,
  {{ dbt_utils.generate_surrogate_key(['benchmark_id']) }} AS id_benchmark,
  mid.id_model,
  benchmark_id,
  puntuacion,
  fecha
FROM deduped s
LEFT JOIN {{ ref('stg_model_union_ids') }} mid
    ON mid.model_name_order = s.model_name_order
WHERE s.rn = 1
{% if is_incremental() %}
  and fecha > (select coalesce(max(fecha), '1900-01-01') from {{ this }})
{% endif %}
