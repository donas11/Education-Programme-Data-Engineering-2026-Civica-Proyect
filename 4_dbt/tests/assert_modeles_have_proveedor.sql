{{ config(severity = 'warn') }}

with modelos_sin_proveedor as (
  select id_modelo, nombre_comercial, id_proveedor
  from {{ ref('modelo') }}
  where id_proveedor is null
)

select * from modelos_sin_proveedor
