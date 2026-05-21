with precios_sin_modelo as (
  select id_precio_modelo, id_modelo, precio_por_M_entrada, precio_por_M_salida
  from {{ ref('precio_modelo') }}
  where id_modelo is null
)

select * from precios_sin_modelo
