{{ config(materialized='table') }}

with reasoning_benchmarks as (
    select id_benchmark, nombre_corto
    from {{ ref('dim_benchmark') }}
    where nombre_corto in ('GPQA Diamond', 'AIME 2025', 'MATH-500', 'LiveBench', 'OlympiadBench')
),

reasoning_scores as (
    select
        fb.id_model,
        dm.nombre_comercial as modelo_nombre,
        dm.nombre_proveedor,
        dm.familia_nombre,
        db.nombre_area_competencia,
        db.nombre_corto as benchmark_nombre,
        fb.puntuacion,
        df.fecha
    from {{ ref('fct_benchmark') }} fb
    inner join reasoning_benchmarks rb on fb.id_benchmark = rb.id_benchmark
    join {{ ref('dim_modelo') }} dm on fb.id_model = dm.id_modelo
    join {{ ref('dim_benchmark') }} db on fb.id_benchmark = db.id_benchmark
    join {{ ref('dim_fecha') }} df on fb.id_fecha = df.id_fecha
),

model_reasoning_agg as (
    select
        id_model,
        modelo_nombre,
        nombre_proveedor,
        familia_nombre,
        count(distinct benchmark_nombre) as num_benchmarks_reasoning,
        avg(puntuacion) as puntuacion_promedio_reasoning,
        max(puntuacion) as puntuacion_maxima_reasoning,
        min(puntuacion) as puntuacion_minima_reasoning
    from reasoning_scores
    group by
        id_model,
        modelo_nombre,
        nombre_proveedor,
        familia_nombre
),

model_precios as (
    select
        id_modelo,
        avg(precio_por_M_entrada) as precio_promedio_entrada,
        avg(precio_por_M_salida) as precio_promedio_salida,
        (avg(precio_por_M_entrada) + avg(precio_por_M_salida)) / 2 as precio_promedio_total
    from {{ ref('fct_precio') }}
    where precio_por_M_entrada > 0 or precio_por_M_salida > 0
    group by id_modelo
),

combined as (
    select
        mra.id_model,
        mra.modelo_nombre,
        mra.nombre_proveedor,
        mra.familia_nombre,
        mra.num_benchmarks_reasoning,
        mra.puntuacion_promedio_reasoning,
        mra.puntuacion_maxima_reasoning,
        mra.puntuacion_minima_reasoning,
        coalesce(mp.precio_promedio_entrada, 0) as precio_promedio_entrada,
        coalesce(mp.precio_promedio_salida, 0) as precio_promedio_salida,
        coalesce(mp.precio_promedio_total, 0) as precio_promedio_total,
        case
            when coalesce(mp.precio_promedio_total, 0) > 0
                then round(mra.puntuacion_promedio_reasoning / mp.precio_promedio_total, 4)
            when mra.puntuacion_promedio_reasoning > 0
                then round(mra.puntuacion_promedio_reasoning * 1000, 4)
            else 0
        end as score_valor_reasoning
    from model_reasoning_agg mra
    left join model_precios mp on mra.id_model = mp.id_modelo
),

ranked as (
    select
        *,
        rank() over (order by puntuacion_promedio_reasoning desc) as ranking_por_rendimiento,
        rank() over (order by score_valor_reasoning desc) as ranking_por_valor
    from combined
)

select
    id_model,
    modelo_nombre,
    nombre_proveedor,
    familia_nombre,
    num_benchmarks_reasoning,
    puntuacion_promedio_reasoning,
    puntuacion_maxima_reasoning,
    puntuacion_minima_reasoning,
    precio_promedio_entrada,
    precio_promedio_salida,
    precio_promedio_total,
    score_valor_reasoning,
    ranking_por_rendimiento,
    ranking_por_valor
from ranked
order by score_valor_reasoning desc
