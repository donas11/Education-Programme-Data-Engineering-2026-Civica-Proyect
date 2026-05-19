 {{ config(
  schema = 'SILVER',
  materialized = 'table'
) }}


with ids as (
  select distinct
    id_model,
    model_name_order
  from {{ ref('stg_model_union_ids') }}
),


oprtn as (
  select
    {{ model_orden_nombre('nombre')}} as model_name_order,
    {{clean_model_name('nombre') }}                          as nombre_comercial,
    ES_FREE,
	ES_REASONING,
	ES_CACHED,
	ES_BATCH,    
    {{clean_price('INPUT_1_M')}}
    {{clean_price('INPUT_1_M')}} 
	{{clean_price('OUTPUT_1_M')}} 
	{{clean_price('CACHE_READ_1_M')}} 
	{{clean_price('CACHE_WRITE_1_M')}} 
	{{clean_price('REASONING_1_M')}}

   
  from {{ source('bronze_raw', 'new_nuevo_openrouter_modelos') }} 
),

Modelo_precios as (
select 
   ids.id_model,
    {{ model_orden_nombre('nombre')}}                        as model_name_order,
    {{clean_model_name('nombre') }}                          as nombre_comercial,
    ES_FREE,
	ES_REASONING,
	ES_CACHED,
	ES_BATCH,    
    {{clean_price('INPUT_1_M')}} as INPUT_1_M,
	{{clean_price('OUTPUT_1_M')}} as OUTPUT_1_M,
	{{clean_price('CACHE_READ_1_M')}} as CACHE_READ_1_M,
	{{clean_price('CACHE_WRITE_1_M')}} as CACHE_WRITE_1_M,
	{{clean_price('REASONING_1_M')}} as REASONING_1_M,
    created as fecha 
 from ids   
 left join oprtn on oprtn.model_name_order = ids.model_name_order
),


joined AS (
  SELECT
    {{ dbt_utils.generate_surrogate_key(['d.provider','d.model_name']) }} AS id_precio_modelo,
    m.id_modelo,
    pp.id_plan_precio    AS id_plan_precio
    
    case tipo_plan
        when 'Free'      then 0
        when 'Standard'  then m.INPUT_1_M
        when 'Reasoning' then m.INPUT_1_M
        when 'Cached'    then m.CACHE_READ_1_M
        when 'Batch'     then m.INPUT_1_M * 0.5  -- descuento típico 50%
    end as precio_por_M_entrada,
    
    case tipo_plan
        when 'Free'      then 0
        when 'Standard'  then m.OUTPUT_1_M
        when 'Reasoning' then m.REASONING_1_M
        when 'Cached'    then m.CACHE_WRITE_1_M
        when 'Batch'     then m.OUTPUT_1_M * 0.5  -- descuento típico 50%
    end as precio_por_M_salida,
    
    
    m.fecha              AS fecha,
    mon.id_moneda        AS moneda,
    

  FROM Modelo_precios m
  LEFT JOIN 
    ON m.nombre_comercial = d.model_name
  LEFT JOIN {{ ref('moneda') }} mon
    ON mon.nombre = '$'   -- moneda por defecto
  LEFT JOIN {{ ref('plan_precio') }} pp
    ON pp.id_modelo = m.id_modelo
)

SELECT * FROM joined;