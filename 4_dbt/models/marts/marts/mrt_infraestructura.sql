{{ config(materialized='table') }}

select
    s.id_servidor,
    p.proveedor as nombre_proveedor,
    s.nombre as modelo_servidor,
    s.num_gpus,
    s.vram_total_gb,
    s.ram_gb,
    s.precio_on_demand_hr,
    s.precio_spot_hr,
    s.precio_mensual,
    s.egress_fees_gb,
    s.moneda,
    g.id_gpu,
    g.nombre_comercial as gpu_nombre,
    g.arquitectura,
    g.vram_gb as gpu_vram_gb,
    g.ancho_banda_gbs,
    g.tdp_w,
    g.fp16_tflops,
    case
        when s.num_gpus > 0 then s.precio_on_demand_hr / s.num_gpus
        else null
    end as precio_on_demand_por_gpu,
    case
        when s.num_gpus > 0 then s.precio_spot_hr / s.num_gpus
        else null
    end as precio_spot_por_gpu,
    case
        when g.fp16_tflops > 0 and s.num_gpus > 0 then s.precio_on_demand_hr / (g.fp16_tflops * s.num_gpus)
        else null
    end as costo_por_tflop
from {{ ref('stg_servidor') }} s
left join {{ ref('stg_gpu') }} g on s.id_gpu = g.id_gpu
left join {{ ref('proveedor') }} p on s.id_proveedor = p.id_proveedor
