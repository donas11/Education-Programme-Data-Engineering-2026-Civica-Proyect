{{ config(
    materialized = 'incremental',
    unique_key = 'id_precio_modelo',
    on_schema_change = 'append_new_columns'
) }}

with model_ids as (
  select id_model, model_name_order
  from {{ ref('stg_model_union_ids') }}
),

precios_base as (
  select
    mi.id_model,
    ES_FREE,
    ES_REASONING,
    ES_CACHED,
    ES_BATCH,
    {{clean_price('INPUT_1_M')}} AS INPUT_1_M,
    {{clean_price('OUTPUT_1_M')}} as OUTPUT_1_M,
    {{clean_price('CACHE_READ_1_M')}} as CACHE_READ_1_M,
    {{clean_price('CACHE_WRITE_1_M')}} as CACHE_WRITE_1_M,
    {{clean_price('REASONING_1_M')}} as REASONING_1_M,
    created as fecha
  from {{ source('bronze_raw', 'new_nuevo_openrouter_modelos') }} raw
  join model_ids mi on mi.model_name_order = {{ model_orden_nombre('model_id') }}
),

planes as (
  select distinct
    id_modelo,
    tipo_plan,
    unidad_facturacion
  from {{ ref('stg_planes') }}
),

joined as (
  select
    {{ dbt_utils.generate_surrogate_key(['p.id_modelo', 'p.tipo_plan']) }} AS id_precio_modelo,
    p.id_modelo,
    pp.id_plan_precio,
    pb.fecha,
    p.tipo_plan,
    p.unidad_facturacion,
    case p.tipo_plan
        when 'Free'      then 0
        when 'Standard'  then pb.INPUT_1_M
        when 'Reasoning' then pb.INPUT_1_M
        when 'Cached'    then pb.CACHE_READ_1_M
        when 'Batch'     then pb.INPUT_1_M * 0.5
    end as precio_por_M_entrada,
    case p.tipo_plan
        when 'Free'      then 0
        when 'Standard'  then pb.OUTPUT_1_M
        when 'Reasoning' then pb.REASONING_1_M
        when 'Cached'    then pb.CACHE_WRITE_1_M
        when 'Batch'     then pb.OUTPUT_1_M * 0.5
    end as precio_por_M_salida
  from planes p
  left join precios_base pb on pb.id_model = p.id_modelo
  left join {{ ref('plan_precio') }} pp on pp.id_modelo = p.id_modelo and pp.tipo_plan = p.tipo_plan
)

select * from joined
{% if is_incremental() %}
  where fecha > (select coalesce(max(fecha), '1900-01-01') from {{ this }})
{% endif %}
