{{ config(materialized='table') }}

with model_scores as (
    select
        fb.id_model,
        dm.nombre_comercial as modelo_nombre,
        dm.nombre_proveedor,
        dm.familia_nombre,
        db.nombre_area_competencia,
        avg(fb.puntuacion) as puntuacion_promedio_area,
        count(*) as num_evaluaciones_area
    from {{ ref('fct_benchmark') }} fb
    join {{ ref('dim_modelo') }} dm on fb.id_model = dm.id_modelo
    join {{ ref('dim_benchmark') }} db on fb.id_benchmark = db.id_benchmark
    group by
        fb.id_model,
        dm.nombre_comercial,
        dm.nombre_proveedor,
        dm.familia_nombre,
        db.nombre_area_competencia
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
        ms.id_model,
        ms.modelo_nombre,
        ms.nombre_proveedor,
        ms.familia_nombre,
        ms.nombre_area_competencia,
        ms.puntuacion_promedio_area,
        ms.num_evaluaciones_area,
        coalesce(mp.precio_promedio_entrada, 0) as precio_promedio_entrada,
        coalesce(mp.precio_promedio_salida, 0) as precio_promedio_salida,
        coalesce(mp.precio_promedio_total, 0) as precio_promedio_total,
        case
            when coalesce(mp.precio_promedio_total, 0) > 0
                then ms.puntuacion_promedio_area / mp.precio_promedio_total
            when ms.puntuacion_promedio_area > 0
                then ms.puntuacion_promedio_area * 1000
            else 0
        end as score_valor
    from model_scores ms
    left join model_precios mp on ms.id_model = mp.id_modelo
),

ranked as (
    select
        *,
        rank() over (partition by nombre_area_competencia order by score_valor desc) as ranking_area,
        rank() over (order by score_valor desc) as ranking_global
    from combined
)

select
    id_model,
    modelo_nombre,
    nombre_proveedor,
    familia_nombre,
    nombre_area_competencia,
    puntuacion_promedio_area,
    num_evaluaciones_area,
    precio_promedio_entrada,
    precio_promedio_salida,
    precio_promedio_total,
    round(score_valor, 4) as score_valor,
    ranking_area,
    ranking_global
from ranked
order by score_valor desc
