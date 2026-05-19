{{ config(
  schema = 'SILVER',
  materialized = 'table'
) }}

-- planes desde el seed y le añadimos la unidad de facturación
WITH planes_ref AS (
  SELECT
    plan               AS tipo_plan,
    'token por millon' unidad_facturacion
  from {{ source('bronze_raw', 'seed_planes') }}
),



with ids as (
  select distinct
    id_model,
    model_name_order
  from {{ ref('stg_model_union_ids') }}
),


or_ as (
  select
    {{ model_orden_nombre('nombre')}} as model_name_order,
    {{clean_model_name('nombre') }}                          as nombre_comercial,
     case when es_free ilike '%Sí%' then true else false end as es_free,
    case when es_reasoning ilike '%	Sí%' then true else false end as es_reasoning,
    case when es_cached ilike '%	Sí%' then true else false end as es_cached,
    case when es_batch ilike '%	Sí%' then true else false end as es_batch,
    
  from {{ source('bronze_raw', 'nuevo_openrouter_modelos') }}
),

op_ as (
  select
    {{model_orden_nombre(extract_canonical_model_name('model_id',2))}} as model_name_order,
    {{clean_model_name(extract_canonical_model_name('model_id',2))}} as nombre_comercial,
    case when es_free ilike '%	Sí%' then true else false end as es_free,
    case when es_reasoning ilike '%	Sí%' then true else false end as es_reasoning,
    case when es_cached ilike '%	Sí%' then true else false end as es_cached,
    case when es_batch ilike '%	Sí%' then true else false end as es_batch,

  from {{ source('bronze_raw', 'new_nuevo_openrouter_modelos') }}
),

with referecia_model as(
    select
        ids.id_model,
        coalesce(or_.nombre_comercial,op_.nombre_comercial) as nombre_comercial
        coalesce(or_.nombre_comercial,op_.nombre_comercial) as es_free,
        coalesce(or_.nombre_comercial,op_.nombre_comercial) as es_reasoning,
        coalesce(or_.nombre_comercial,op_.nombre_comercial) as es_cached,
        coalesce(or_.nombre_comercial,op_.nombre_comercial) as es_batch,
    from ids
    left join or_ on or_.model_name_order = ids.model_name_order
    left join op_ on op_.model_name_order = ids.model_name_order
),


planes_activos as (

  select id_modelo, 'Free'      as tipo_plan from referecia_model where es_free      = true
  union all
  select id_modelo, 'Standard'  as tipo_plan from referecia_model where es_standard  = true
  union all
  select id_modelo, 'Reasoning' as tipo_plan from referecia_model where es_reasoning = true
  union all
  select id_modelo, 'Cached'    as tipo_plan from referecia_model where es_cached    = true
  union all
  select id_modelo, 'Batch'     as tipo_plan from referecia_model where es_batch     = true

),



WITH base AS (
  SELECT
    m.id_modelo AS id_modelo,
    r.id_region AS id_region,
    pa.tipo_plan   AS tipo_plan,
    'token por millon' AS unidad_facturacion
  FROM {{ ref('modelo') }} m
  JOIN planes_activos pa 
    ON m.id_modelo=pa.id_modelo
  LEFT JOIN {{ ref('region') }} r  
    ON r.region = 'Global'
  
)

SELECT * FROM base
