{{ config(materialized='table') }}  
with ids as (
  select distinct
    id_model,
    model_name_order
  from {{ ref('stg_model_union_ids') }}
),

nm_raw as (
  select
    {{ model_orden_nombre('model_id')}} as model_name_order,
    {{clean_model_name('model_id')}}                            as nombre_comercial,
    provider,
    model_family                                          as familia_nombre,
    context_window_k * 1000                               as context_window,
    case when modality ilike '%Vision%'
          or modality ilike '%Audio%'
          or modality ilike '%Video%' then true else false end as multimodal,
    case when open_weight = 1 then true
         when open_weight = 0 then false
         else null end                                    as opensource,
    try_cast(release_date as date)                        as fecha_lanzamiento
  from {{ source('bronze_raw', 'models') }}
),

nm as (
  select *
  from (
    select *,
      row_number() over (partition by model_name_order order by context_window desc) as rn
    from nm_raw
  )
  where rn = 1
),

-- ── FUENTE 2: OpenRouter ─────────────────────────────────────────────
or_raw as (
  select
    {{ model_orden_nombre('nombre')}} as model_name_order,
    {{clean_model_name('nombre') }}                          as nombre_comercial,
    {{extract_canonical_model_name('id',1)}}              as provider,
    null::varchar                                         as familia_nombre,
    context_length                                        as context_window,
    null::boolean                                         as multimodal,
    null::boolean                                         as opensource,
    null::date                                            as fecha_lanzamiento
  from {{ source('bronze_raw', 'nuevo_openrouter_modelos') }}
),

or_ as (
  select *
  from (
    select *,
      row_number() over (partition by model_name_order order by context_window desc) as rn
    from or_raw
  )
  where rn = 1
),

op_raw as (
  select
    {{model_orden_nombre(extract_canonical_model_name('model_id',2))}} as model_name_order,
    {{clean_model_name(extract_canonical_model_name('model_id',2))}} as nombre_comercial,
    {{extract_canonical_model_name('model_id',1)}}       as provider,
    NULLIF(tokenizer,'other')                            as familia_nombre,
    total_context                                        as context_window,
    case when modality ilike '%Vision%'
          or modality ilike '%Audio%'
          or modality ilike '%Video%' then true else false end as multimodal,
    null::boolean                                        as opensource,
    created                                              as fecha_lanzamiento
  from {{ source('bronze_raw', 'new_nuevo_openrouter_modelos') }}
),

op_ as (
  select *
  from (
    select *,
      row_number() over (partition by model_name_order order by context_window desc) as rn
    from op_raw
  )
  where rn = 1
),

-- ── FUENTE 3: llm_model_comparison_2026 ─────────────────────────────
lc_raw as (
  select
    {{ model_orden_nombre('Model')}} as model_name_order,
    {{ clean_model_name('Model')}}                      as nombre_comercial,
    provider,
    null::varchar                                         as familia_nombre,
    try_cast(context_window as int)                       as context_window,
    case when lower(cast(multimodal as varchar)) = 'true'  then true
         when lower(cast(multimodal as varchar)) = 'false' then false
         else null end                                    as multimodal,
    case when lower(cast(open_source as varchar)) = 'true'  then true
         when lower(cast(open_source as varchar)) = 'false' then false
         else null end                                    as opensource,
    null::date                                            as fecha_lanzamiento
  from {{ source('bronze_raw', 'llm_model_comparison_2026') }}
),

lc as (
  select *
  from (
    select *,
      row_number() over (partition by model_name_order order by context_window desc) as rn
    from lc_raw
  )
  where rn = 1
),

-- ── FUENTE 4: ai_models_performance ─────────────────────────────────
ap_raw as (
  select
     {{ model_orden_nombre('Model')}} as model_name_order,
     {{ clean_model_name('Model')}}                      as nombre_comercial,
    Creator                                             as provider,
    null::varchar                                         as familia_nombre,
    null::int                                             as context_window,
    null::boolean                                         as multimodal,
    null::boolean                                         as opensource,
    null::date                                            as fecha_lanzamiento
  from {{ source('bronze_raw', 'ai_models_performance') }}
),

ap as (
  select *
  from (
    select *,
      row_number() over (partition by model_name_order order by provider) as rn
    from ap_raw
  )
  where rn = 1
),

-- ── FUENTE 5: llm_complete_dataset ──────────────────────────────────
cd_raw as (
  select
    {{ model_orden_nombre('model_name')}} as model_name_order,
    {{ clean_model_name('model_name')}}                      as nombre_comercial,
    provider,
    family                                                as familia_nombre,
    context_window_k * 1000                               as context_window,
    case when modality ilike '%Vision%'
          or modality ilike '%Audio%' then true else false end as multimodal,
    case when lower(cast(open_source as varchar)) = 'true'  then true
         when lower(cast(open_source as varchar)) = 'false' then false
         else null end                                    as opensource,
    try_cast(release_date as date)                        as fecha_lanzamiento
  from {{ source('bronze_raw', 'llm_complete_dataset') }}
),

cd as (
  select *
  from (
    select *,
      row_number() over (partition by model_name_order order by context_window desc) as rn
    from cd_raw
  )
  where rn = 1
)

-- ── JOIN: id_model como ancla, COALESCE por columna ─────────────────
select
  ids.id_model,
  coalesce(nm.nombre_comercial, lc.nombre_comercial, cd.nombre_comercial, or_.nombre_comercial,op_.nombre_comercial) as nombre_comercial,
  coalesce(nm.provider,       ap.provider,   lc.provider,   cd.provider, op_.provider)                      as provider,
  coalesce(nm.familia_nombre, cd.familia_nombre, op_.familia_nombre)                                        as familia_nombre,
  coalesce(nm.context_window, lc.context_window, cd.context_window, or_.context_window, op_.context_window)  as context_window,
  coalesce(nm.multimodal,     lc.multimodal,  cd.multimodal, op_.multimodal)                                 as multimodal,
  coalesce(nm.opensource,     lc.opensource,  cd.opensource)                                                as opensource,
  coalesce(nm.fecha_lanzamiento, cd.fecha_lanzamiento, op_.fecha_lanzamiento)                               as fecha_lanzamiento

from ids
left join nm  on nm.model_name_order  = ids.model_name_order
left join or_ on or_.model_name_order = ids.model_name_order
left join op_ on op_.model_name_order = ids.model_name_order
left join lc  on lc.model_name_order  = ids.model_name_order
left join ap  on ap.model_name_order  = ids.model_name_order
left join cd  on cd.model_name_order  = ids.model_name_order
