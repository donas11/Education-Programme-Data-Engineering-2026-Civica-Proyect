{{ config(materialized='table') }}

select
    id_proveedor,
    proveedor as nombre_proveedor,
    tipo_proveedor
from {{ ref('proveedor') }}
