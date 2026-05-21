{{ config(materialized='table') }}

with provider_models as (
    select
        dm.nombre_proveedor,
        count(distinct dm.id_modelo) as num_modelos,
        count(distinct dm.familia_nombre) as num_familias,
        avg(dm.context_window) as avg_context_window,
        max(dm.context_window) as max_context_window,
        sum(case when dm.multimodal = true then 1 else 0 end) as num_modelos_multimodal,
        sum(case when dm.opensource = true then 1 else 0 end) as num_modelos_opensource
    from {{ ref('dim_modelo') }} dm
    where dm.nombre_proveedor is not null
    group by dm.nombre_proveedor
),

provider_scores as (
    select
        dm.nombre_proveedor,
        avg(fb.puntuacion) as avg_puntuacion,
        count(distinct fb.id_model) as num_modelos_con_scores,
        count(distinct fb.id_benchmark) as num_benchmarks_totales
    from {{ ref('fct_benchmark') }} fb
    join {{ ref('dim_modelo') }} dm on fb.id_model = dm.id_modelo
    where dm.nombre_proveedor is not null
    group by dm.nombre_proveedor
),

provider_pricing as (
    select
        dm.nombre_proveedor,
        avg(fp.precio_por_M_entrada) as avg_precio_entrada,
        min(fp.precio_por_M_entrada) as min_precio_entrada,
        max(fp.precio_por_M_entrada) as max_precio_entrada,
        avg(fp.precio_por_M_salida) as avg_precio_salida,
        min(fp.precio_por_M_salida) as min_precio_salida,
        max(fp.precio_por_M_salida) as max_precio_salida,
        count(distinct fp.id_modelo) as num_modelos_con_precio
    from {{ ref('fct_precio') }} fp
    join {{ ref('dim_modelo') }} dm on fp.id_modelo = dm.id_modelo
    where dm.nombre_proveedor is not null
    group by dm.nombre_proveedor
),

provider_infrastructure as (
    select
        mi.nombre_proveedor,
        count(distinct mi.id_servidor) as num_servidores,
        count(distinct mi.gpu_nombre) as num_tipos_gpu,
        avg(mi.num_gpus) as avg_gpus_por_servidor,
        avg(mi.precio_on_demand_hr) as avg_precio_on_demand,
        min(mi.precio_on_demand_hr) as min_precio_on_demand,
        max(mi.precio_on_demand_hr) as max_precio_on_demand,
        avg(mi.precio_spot_hr) as avg_precio_spot,
        avg(mi.precio_mensual) as avg_precio_mensual,
        avg(mi.egress_fees_gb) as avg_egress_fees,
        avg(mi.fp16_tflops) as avg_fp16_tflops,
        avg(mi.vram_total_gb) as avg_vram_total
    from {{ ref('mrt_infraestructura') }} mi
    where mi.nombre_proveedor is not null
    group by mi.nombre_proveedor
),

provider_combined as (
    select
        pm.nombre_proveedor,
        pm.num_modelos,
        pm.num_familias,
        pm.avg_context_window,
        pm.max_context_window,
        pm.num_modelos_multimodal,
        pm.num_modelos_opensource,
        coalesce(ps.avg_puntuacion, 0) as avg_puntuacion,
        coalesce(ps.num_benchmarks_totales, 0) as num_benchmarks_totales,
        pp.avg_precio_entrada,
        pp.min_precio_entrada,
        pp.max_precio_entrada,
        pp.avg_precio_salida,
        pp.min_precio_salida,
        pp.max_precio_salida,
        pp.num_modelos_con_precio,
        pi.num_servidores,
        pi.num_tipos_gpu,
        pi.avg_gpus_por_servidor,
        pi.avg_precio_on_demand,
        pi.min_precio_on_demand,
        pi.max_precio_on_demand,
        pi.avg_precio_spot,
        pi.avg_precio_mensual,
        pi.avg_egress_fees,
        pi.avg_fp16_tflops,
        pi.avg_vram_total,
        case
            when pp.avg_precio_entrada > 0 and pp.avg_precio_salida > 0
                then round((pp.avg_precio_entrada + pp.avg_precio_salida) / 2, 4)
            else null
        end as avg_precio_total_tokens,
        rank() over (order by pm.num_modelos desc) as ranking_por_num_modelos,
        rank() over (order by coalesce(ps.avg_puntuacion, 0) desc) as ranking_por_puntuacion,
        rank() over (order by pp.avg_precio_entrada asc nulls last) as ranking_por_precio_entrada
    from provider_models pm
    left join provider_scores ps on pm.nombre_proveedor = ps.nombre_proveedor
    left join provider_pricing pp on pm.nombre_proveedor = pp.nombre_proveedor
    left join provider_infrastructure pi on pm.nombre_proveedor = pi.nombre_proveedor
)

select
    nombre_proveedor,
    num_modelos,
    num_familias,
    round(avg_context_window, 0) as avg_context_window,
    max_context_window,
    num_modelos_multimodal,
    num_modelos_opensource,
    round(avg_puntuacion, 2) as avg_puntuacion,
    num_benchmarks_totales,
    round(avg_precio_entrada, 4) as avg_precio_entrada,
    round(min_precio_entrada, 4) as min_precio_entrada,
    round(max_precio_entrada, 4) as max_precio_entrada,
    round(avg_precio_salida, 4) as avg_precio_salida,
    round(min_precio_salida, 4) as min_precio_salida,
    round(max_precio_salida, 4) as max_precio_salida,
    num_modelos_con_precio,
    num_servidores,
    num_tipos_gpu,
    round(avg_gpus_por_servidor, 1) as avg_gpus_por_servidor,
    round(avg_precio_on_demand, 4) as avg_precio_on_demand,
    round(min_precio_on_demand, 4) as min_precio_on_demand,
    round(max_precio_on_demand, 4) as max_precio_on_demand,
    round(avg_precio_spot, 4) as avg_precio_spot,
    round(avg_precio_mensual, 2) as avg_precio_mensual,
    round(avg_egress_fees, 4) as avg_egress_fees,
    round(avg_fp16_tflops, 2) as avg_fp16_tflops,
    round(avg_vram_total, 0) as avg_vram_total,
    avg_precio_total_tokens,
    ranking_por_num_modelos,
    ranking_por_puntuacion,
    ranking_por_precio_entrada
from provider_combined
order by ranking_por_num_modelos
