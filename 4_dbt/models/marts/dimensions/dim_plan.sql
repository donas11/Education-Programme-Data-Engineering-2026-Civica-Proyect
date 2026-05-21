{{ config(materialized='table') }}

select distinct
    {{ dbt_utils.generate_surrogate_key(['tipo_plan', 'unidad_facturacion']) }} as id_plan_precio,
    tipo_plan,
    unidad_facturacion
from {{ ref('stg_planes') }}
