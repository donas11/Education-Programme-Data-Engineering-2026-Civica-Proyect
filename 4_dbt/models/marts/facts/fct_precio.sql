{{ config(materialized='table') }}

select
    pm.id_precio_modelo,
    pm.id_modelo,
    pm.id_plan_precio,
    pp.id_region,
    df.id_fecha,
    pm.precio_por_M_entrada,
    pm.precio_por_M_salida
from {{ ref('precio_modelo') }} pm
join {{ ref('dim_fecha') }} df on pm.fecha = df.fecha
left join {{ ref('plan_precio') }} pp on pm.id_plan_precio = pp.id_plan_precio
