{{ config(materialized='table') }}

with api_costs as (
    select
        dm.nombre_comercial as modelo_nombre,
        dm.nombre_proveedor,
        dm.familia_nombre,
        avg(fp.precio_por_M_entrada) as avg_api_precio_entrada,
        avg(fp.precio_por_M_salida) as avg_api_precio_salida,
        (avg(fp.precio_por_M_entrada) + avg(fp.precio_por_M_salida)) / 2 as avg_api_precio_total
    from {{ ref('fct_precio') }} fp
    join {{ ref('dim_modelo') }} dm on fp.id_modelo = dm.id_modelo
    where fp.precio_por_M_entrada > 0 or fp.precio_por_M_salida > 0
    group by
        dm.nombre_comercial,
        dm.nombre_proveedor,
        dm.familia_nombre
),

selfhosted_costs as (
    select
        mi.gpu_nombre,
        mi.nombre_proveedor,
        mi.precio_on_demand_hr,
        mi.precio_spot_hr,
        mi.precio_mensual,
        mi.num_gpus,
        mi.fp16_tflops,
        mi.precio_on_demand_por_gpu,
        mi.precio_spot_por_gpu,
        mi.costo_por_tflop
    from {{ ref('mrt_infraestructura') }} mi
),

api_per_1m_tokens as (
    select
        modelo_nombre,
        nombre_proveedor as api_proveedor,
        familia_nombre,
        avg_api_precio_entrada,
        avg_api_precio_salida,
        avg_api_precio_total,
        avg_api_precio_total * 1000 as costo_api_1B_tokens
    from api_costs
),

selfhosted_per_1B_tokens as (
    select
        gpu_nombre,
        nombre_proveedor as infra_proveedor,
        precio_on_demand_hr,
        precio_spot_hr,
        precio_mensual,
        num_gpus,
        fp16_tflops,
        precio_on_demand_por_gpu,
        precio_spot_por_gpu,
        costo_por_tflop,
        case
            when fp16_tflops > 0 then round(precio_on_demand_hr / (fp16_tflops * 1000), 6)
            else null
        end as costo_por_1B_ops_on_demand,
        case
            when fp16_tflops > 0 then round(precio_spot_hr / (fp16_tflops * 1000), 6)
            else null
        end as costo_por_1B_ops_spot
    from selfhosted_costs
),

comparison as (
    select
        ap.modelo_nombre,
        ap.familia_nombre,
        ap.api_proveedor,
        ap.avg_api_precio_entrada,
        ap.avg_api_precio_salida,
        ap.avg_api_precio_total,
        ap.costo_api_1B_tokens,
        sh.gpu_nombre,
        sh.infra_proveedor,
        sh.precio_on_demand_hr,
        sh.precio_spot_hr,
        sh.precio_mensual,
        sh.num_gpus,
        sh.fp16_tflops,
        sh.costo_por_1B_ops_on_demand,
        sh.costo_por_1B_ops_spot,
        case
            when sh.costo_por_1B_ops_on_demand > 0
                then round(ap.costo_api_1B_tokens / sh.costo_por_1B_ops_on_demand, 2)
            else null
        end as ratio_api_vs_selfhosted_on_demand,
        case
            when sh.costo_por_1B_ops_spot > 0
                then round(ap.costo_api_1B_tokens / sh.costo_por_1B_ops_spot, 2)
            else null
        end as ratio_api_vs_selfhosted_spot
    from api_per_1m_tokens ap
    cross join selfhosted_per_1B_tokens sh
)

select
    modelo_nombre,
    familia_nombre,
    api_proveedor,
    avg_api_precio_entrada,
    avg_api_precio_salida,
    avg_api_precio_total,
    round(costo_api_1B_tokens, 4) as costo_api_1B_tokens,
    gpu_nombre,
    infra_proveedor,
    precio_on_demand_hr,
    precio_spot_hr,
    precio_mensual,
    num_gpus,
    fp16_tflops,
    costo_por_1B_ops_on_demand,
    costo_por_1B_ops_spot,
    ratio_api_vs_selfhosted_on_demand,
    ratio_api_vs_selfhosted_spot,
    case
        when ratio_api_vs_selfhosted_on_demand > 1 then 'API es mas cara'
        when ratio_api_vs_selfhosted_on_demand < 1 then 'Self-hosted es mas caro'
        else 'Similar'
    end as recomendacion_on_demand,
    case
        when ratio_api_vs_selfhosted_spot > 1 then 'API es mas cara'
        when ratio_api_vs_selfhosted_spot < 1 then 'Self-hosted es mas caro'
        else 'Similar'
    end as recomendacion_spot
from comparison
order by modelo_nombre, api_proveedor, infra_proveedor
