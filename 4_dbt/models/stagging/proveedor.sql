with api as(
  SELECT
    lower(trim({{remove_parentheses_content('proveedor')}})) AS proveedor_normalized,
    proveedor AS proveedor_raw,
    'API'    AS tipo_proveedor
  FROM {{ ref('stg_proveedor') }}
),

instancia as (
  SELECT
    lower(trim({{remove_parentheses_content('proveedor')}})) AS proveedor_normalized,
    proveedor AS proveedor_raw,
    'INSTANCIA'    AS tipo_proveedor
  FROM {{ ref('stg_instancia') }}
),

fusion as (
  select
    coalesce(a.proveedor_normalized, i.proveedor_normalized) as proveedor_normalized,
    coalesce(a.proveedor_raw, i.proveedor_raw) as proveedor_raw,
    case
      when a.proveedor_normalized is not null and i.proveedor_normalized is not null then 'BOTH'
      when a.proveedor_normalized is not null                                        then 'API'
      else                                                                                'INSTANCIA'
    end as tipo_proveedor
  from api a
  full outer join instancia i
    on a.proveedor_normalized = i.proveedor_normalized
),

deduped as (
  select
    proveedor_normalized,
    proveedor_raw,
    tipo_proveedor,
    row_number() over (partition by proveedor_normalized order by
      case tipo_proveedor when 'BOTH' then 1 when 'API' then 2 else 3 end
    ) as rn
  from fusion
)

select
  {{ dbt_utils.generate_surrogate_key(['proveedor_normalized']) }} as id_proveedor,
  upper(proveedor_raw) as proveedor,
  tipo_proveedor
from deduped
where rn = 1
