{{ config(materialized='table') }}

select
    m.id_modelo,
    m.nombre_comercial,
    p.id_proveedor,
    p.proveedor as nombre_proveedor,
    p.tipo_proveedor,
    f.id_familia,
    f.nombre as familia_nombre,
    m.context_window,
    m.multimodal,
    m.opensource,
    m.fecha_lanzamiento
from {{ ref('modelo') }} m
left join {{ ref('proveedor') }} p on m.id_proveedor = p.id_proveedor
left join {{ ref('familia') }} f on m.id_familia = f.id_familia
