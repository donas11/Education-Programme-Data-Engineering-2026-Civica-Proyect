{{ config(materialized='view') }}

with src as (
    select
        {{ model_orden_nombre('model') }} as model_name_order,
        try_cast(intelligence_index as float) as intelligence_index,
        try_cast(regexp_replace(speed_median_token_sx, '[^0-9.]', '') as float) as speed_tps,
        try_cast(regexp_replace(latency_first_answer_chunk_sx, '[^0-9.]', '') as float) / 1000 as latency_s,
        try_cast(regexp_replace(price_blended_usd_1_m_tokensx, '[^0-9.]', '') as float) as price_blended,
        null::varchar as tier,
        current_date() as fecha_valor
    from {{ source('bronze_raw', 'ai_models_performance') }}
),

deduped as (
    select
        model_name_order,
        intelligence_index,
        speed_tps,
        latency_s,
        price_blended,
        tier,
        fecha_valor,
        row_number() over (partition by model_name_order order by intelligence_index desc) as rn
    from src
)

select
    {{ dbt_utils.generate_surrogate_key(['d.model_name_order', 'd.fecha_valor']) }} as id_performance,
    mid.id_model as id_modelo,
    d.intelligence_index,
    d.speed_tps,
    d.latency_s,
    d.price_blended,
    d.tier,
    d.fecha_valor,
    case when d.rn = 1 then true else false end as is_current
from deduped d
left join {{ ref('stg_model_union_ids') }} mid
    on mid.model_name_order = d.model_name_order
where d.rn = 1
