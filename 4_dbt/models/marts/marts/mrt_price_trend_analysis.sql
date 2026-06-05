{{ config(materialized='table') }}

with precio_base as (
    select
        fp.id_modelo,
        dm.nombre_comercial as modelo_nombre,
        dm.nombre_proveedor,
        dm.familia_nombre,
        df.fecha_valor,
        fp.precio_por_M_entrada,
        fp.precio_por_M_salida,
        (fp.precio_por_M_entrada + fp.precio_por_M_salida) / 2 as precio_promedio
    from {{ ref('fct_precio') }} fp
    join {{ ref('dim_modelo') }} dm on fp.id_modelo = dm.id_modelo
    join {{ ref('dim_fecha') }} df on fp.id_fecha = df.id_fecha
),

with_lag as (
    select
        *,
        lag(precio_por_M_entrada) over (partition by id_modelo order by fecha_valor) as precio_entrada_anterior,
        lag(precio_por_M_salida) over (partition by id_modelo order by fecha_valor) as precio_salida_anterior,
        lag(precio_promedio) over (partition by id_modelo order by fecha_valor) as precio_promedio_anterior,
        min(precio_por_M_entrada) over (partition by id_modelo) as precio_min_entrada,
        max(precio_por_M_entrada) over (partition by id_modelo) as precio_max_entrada,
        min(precio_por_M_salida) over (partition by id_modelo) as precio_min_salida,
        max(precio_por_M_salida) over (partition by id_modelo) as precio_max_salida,
        count(*) over (partition by id_modelo) as num_registros
    from precio_base
),

with_change as (
    select
        *,
        case
            when precio_entrada_anterior is not null and precio_entrada_anterior > 0
                then round(((precio_por_M_entrada - precio_entrada_anterior) / precio_entrada_anterior) * 100, 2)
            else null
        end as pct_cambio_entrada,
        case
            when precio_salida_anterior is not null and precio_salida_anterior > 0
                then round(((precio_por_M_salida - precio_salida_anterior) / precio_salida_anterior) * 100, 2)
            else null
        end as pct_cambio_salida,
        case
            when precio_promedio_anterior is not null and precio_promedio_anterior > 0
                then round(((precio_promedio - precio_promedio_anterior) / precio_promedio_anterior) * 100, 2)
            else null
        end as pct_cambio_promedio
    from with_lag
)

select
    id_modelo,
    modelo_nombre,
    nombre_proveedor,
    familia_nombre,
    fecha_valor,
    precio_por_M_entrada,
    precio_por_M_salida,
    precio_promedio,
    precio_entrada_anterior,
    precio_salida_anterior,
    precio_promedio_anterior,
    precio_min_entrada,
    precio_max_entrada,
    precio_min_salida,
    precio_max_salida,
    num_registros,
    pct_cambio_entrada,
    pct_cambio_salida,
    pct_cambio_promedio
from with_change
order by id_modelo, fecha_valor
