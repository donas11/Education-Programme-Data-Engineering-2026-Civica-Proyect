{{ config(materialized='table') }}

with api_pricing as (
    select
        dm.nombre_comercial as modelo_nombre,
        dm.nombre_proveedor,
        dm.familia_nombre,
        avg(fp.precio_por_M_entrada) as avg_precio_entrada,
        avg(fp.precio_por_M_salida) as avg_precio_salida
    from {{ ref('fct_precio') }} fp
    join {{ ref('dim_modelo') }} dm on fp.id_modelo = dm.id_modelo
    where fp.precio_por_M_entrada > 0 or fp.precio_por_M_salida > 0
    group by
        dm.nombre_comercial,
        dm.nombre_proveedor,
        dm.familia_nombre
),

infra_pricing as (
    select
        mi.gpu_nombre,
        mi.nombre_proveedor,
        mi.precio_on_demand_hr,
        mi.precio_spot_hr,
        mi.precio_mensual,
        mi.num_gpus,
        mi.egress_fees_gb,
        mi.precio_on_demand_por_gpu,
        mi.precio_spot_por_gpu
    from {{ ref('mrt_infraestructura') }} mi
),

usage_scenarios as (
    select '1M_tokens' as escenario, 1000000 as tokens_entrada, 1000000 as tokens_salida, 1 as data_transfer_gb
    union all select '10M_tokens', 10000000, 10000000, 5
    union all select '100M_tokens', 100000000, 100000000, 20
    union all select '1B_tokens', 1000000000, 1000000000, 100
),

api_tco as (
    select
        ap.modelo_nombre,
        ap.nombre_proveedor,
        ap.familia_nombre,
        us.escenario,
        us.tokens_entrada,
        us.tokens_salida,
        us.data_transfer_gb,
        round((us.tokens_entrada / 1000000.0) * ap.avg_precio_entrada, 4) as costo_entrada,
        round((us.tokens_salida / 1000000.0) * ap.avg_precio_salida, 4) as costo_salida,
        round(us.data_transfer_gb * 0.01, 4) as costo_transferencia_api,
        round(
            (us.tokens_entrada / 1000000.0) * ap.avg_precio_entrada +
            (us.tokens_salida / 1000000.0) * ap.avg_precio_salida +
            us.data_transfer_gb * 0.01
        , 4) as costo_total_api
    from api_pricing ap
    cross join usage_scenarios us
),

selfhosted_tco as (
    select
        ip.gpu_nombre,
        ip.nombre_proveedor,
        ip.precio_on_demand_hr,
        ip.precio_spot_hr,
        ip.precio_mensual,
        ip.num_gpus,
        ip.egress_fees_gb,
        us.escenario,
        us.tokens_entrada,
        us.tokens_salida,
        us.data_transfer_gb,
        round(us.data_transfer_gb * coalesce(ip.egress_fees_gb, 0), 4) as costo_transferencia,
        round(ip.precio_on_demand_hr * 720, 4) as costo_mensual_on_demand,
        round(ip.precio_spot_hr * 720, 4) as costo_mensual_spot,
        coalesce(ip.precio_mensual, ip.precio_on_demand_hr * 720) as costo_mensual_servidor
    from infra_pricing ip
    cross join usage_scenarios us
),

tco_comparison as (
    select
        at.modelo_nombre,
        at.nombre_proveedor as api_proveedor,
        at.familia_nombre,
        at.escenario,
        at.tokens_entrada,
        at.tokens_salida,
        at.data_transfer_gb,
        at.costo_entrada,
        at.costo_salida,
        at.costo_transferencia_api,
        at.costo_total_api,
        st.gpu_nombre,
        st.nombre_proveedor as infra_proveedor,
        st.precio_on_demand_hr,
        st.precio_spot_hr,
        st.precio_mensual,
        st.num_gpus,
        st.costo_transferencia as costo_transferencia_infra,
        st.costo_mensual_on_demand,
        st.costo_mensual_spot,
        st.costo_mensual_servidor,
        round(at.costo_total_api / nullif(st.costo_mensual_servidor, 0), 2) as ratio_api_vs_dedicado,
        round(at.costo_total_api / nullif(st.costo_mensual_on_demand, 0), 2) as ratio_api_vs_on_demand
    from api_tco at
    cross join selfhosted_tco st
    where at.escenario = st.escenario
)

select
    modelo_nombre,
    api_proveedor,
    familia_nombre,
    escenario,
    tokens_entrada,
    tokens_salida,
    data_transfer_gb,
    costo_entrada,
    costo_salida,
    costo_transferencia_api,
    costo_total_api,
    gpu_nombre,
    infra_proveedor,
    precio_on_demand_hr,
    precio_spot_hr,
    precio_mensual,
    num_gpus,
    costo_transferencia_infra,
    costo_mensual_on_demand,
    costo_mensual_spot,
    costo_mensual_servidor,
    ratio_api_vs_dedicado,
    ratio_api_vs_on_demand,
    case
        when ratio_api_vs_dedicado > 1 then 'API mas cara'
        when ratio_api_vs_dedicado < 1 then 'Self-hosted mas caro'
        else 'Similar'
    end as recomendacion
from tco_comparison
order by modelo_nombre, escenario, api_proveedor, infra_proveedor
