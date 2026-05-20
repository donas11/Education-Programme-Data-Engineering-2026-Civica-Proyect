with src as (
  select 
    {{ dbt_utils.generate_surrogate_key(['benchmark_id']) }} AS id_benchmark,       
    cast(benchmark_name as varchar) as nombre_corto,
    category,
    CONCAT(full_name,' ',description) as descripcion,
    saturated as saturado
  from {{ source('bronze_raw','benchmarks') }}
)



  SELECT
    s.id_benchmark,
    s.nombre_corto,
    s.descripcion,
    ac.id_area_competencia
  FROM src s
  LEFT JOIN {{ ref('area_competencia') }} ac
    ON ac.area_competencia = s.category
  


