{{ config(materialized='table') }}

select
    b.id_benchmark,
    b.nombre_corto,
    b.descripcion,
    ac.id_area_competencia,
    ac.area_competencia as nombre_area_competencia
from {{ ref('benchmark') }} b
left join {{ ref('area_competencia') }} ac on b.id_area_competencia = ac.id_area_competencia
