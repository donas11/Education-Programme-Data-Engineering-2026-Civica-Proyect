{{ config(materialized='table') }}

select
    tb.id_test,
    tb.id_model,
    tb.id_benchmark,
    df.id_fecha,
    tb.puntuacion,
    tb.benchmark_id
from {{ ref('test_benchmark') }} tb
join {{ ref('dim_fecha') }} df on tb.fecha = df.fecha
