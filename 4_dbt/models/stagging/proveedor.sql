{{ config(materialized='view') }}

with api as(
SELECT
    proveedor AS proveedor,
    'API'    AS tipo_proveedor
  FROM {{ ref('stg_proveedor') }}
),

instancia as (
  SELECT DISTINCT
    proveedor AS proveedor,
    'INSTANCIA'    AS tipo_proveedor
  FROM {{ ref('stg_instancia') }}
),


fusion as (
  select
    coalesce(a.proveedor, i.proveedor) as proveedor,
    case
      when a.proveedor is not null and i.proveedor is not null then 'BOTH'
      when a.proveedor is not null                             then 'API'
      else                                                          'INSTANCIA'
    end as tipo_proveedor
  from api a
  full outer join instancia i
    on lower(trim ({{remove_parentheses_content('a.proveedor')}})) = lower(trim({{remove_parentheses_content('i.proveedor')}}))
)

select
  {{ dbt_utils.generate_surrogate_key(['proveedor']) }} as id_proveedor,
  proveedor,
  tipo_proveedor
from fusion