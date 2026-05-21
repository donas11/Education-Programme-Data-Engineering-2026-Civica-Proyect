{{ config(materialized='view') }}

with source as (
  select * from {{ source('bronze_raw', 'proveedores_servidor') }}
),

-- Fuente con precios por hora, tipo y egress
precios as (
  select
    proveedor                                              as proveedor_raw,
    tipo                                                   as tipo,
    try_to_number(nullif(trim(precio_on_demand_hr), 'Variable')) as precio_on_demand_hr,
    try_to_number(nullif(trim(precio_spot_hr),     'Variable')) as precio_spot_hr,
    try_to_number(nullif(trim(egress_fees_gb),     'Bajo'))     as egress_fees_gb
  from {{ source('bronze_raw', 'proveedores') }}
),

gpu as (
  select id_gpu, nombre_comercial
  from {{ ref('stg_gpu') }}
),

proveedor as (
  select id_proveedor, proveedor
  from {{ ref('proveedor') }}
),

normalized as (
  select
    {{ dbt_utils.generate_surrogate_key(['s.Proveedor', 's.Modelo_Servidor']) }} as id_servidor,

    s.Modelo_Servidor                                      as nombre,
    p.tipo,

    case
      when regexp_like(s.Modelo_Servidor, '\\([0-9]+x')
        then try_cast(regexp_substr(s.Modelo_Servidor, '([0-9]+)x', 1, 1, 'e', 1) as int)
      else 1
    end                                                    as num_gpus,

    s.VRAM_GB                                              as vram_total_gb,
    s.RAM_Sistema_GB                                       as ram_gb,

    p.precio_on_demand_hr,
    p.precio_spot_hr,

    try_to_number(regexp_replace(s.Precio_Mensual, '[^0-9.]', ''))
                                                           as precio_mensual,
    p.egress_fees_gb,

    case
      when s.Precio_Mensual ilike '%EUR%' then 'EUR'
      when s.Precio_Mensual ilike '%USD%' then 'USD'
      else null
    end                                                    as moneda,

    -- FKs
    g.id_gpu,
    prov.id_proveedor,
    row_number() over (partition by s.Proveedor, s.Modelo_Servidor order by p.precio_on_demand_hr desc) as rn

  from source s
  
  left join precios p
    on lower(trim(s.Proveedor)) = lower(trim(split_part(p.proveedor_raw, '(', 1)))
  left join gpu g
    on lower(trim(g.nombre_comercial)) = lower(trim(s.GPU))
  left join proveedor prov
    on lower(trim(prov.proveedor)) = lower(trim(s.Proveedor))
)

select * from normalized where rn = 1