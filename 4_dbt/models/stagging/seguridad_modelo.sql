{{ config(materialized='view') }}

with src as (
    select
        {{ model_orden_nombre('model_id') }} as model_name_order,
        try_cast(toxicity_score_pct as float) as toxicity_score,
        try_cast(bias_score_pct as float) as bias_score,
        try_cast(refusal_rate_pct as float) as refusal_rate,
        try_cast(hallucination_rate_pct as float) as hallucination_rate,
        try_cast(instruction_following_pct as float) as instruction_following,
        try_cast(jailbreak_resistance_pct as float) as jailbreak_resistance,
        try_cast(factuality_score_pct as float) as factuality_score,
        case when rlhf_aligned ilike '%true%' then true else false end as rlhf_aligned,
        safety_training,
        current_date() as fecha
    from {{ source('bronze_raw', 'safety_alignment') }}
),

deduped as (
    select
        model_name_order,
        toxicity_score,
        bias_score,
        refusal_rate,
        hallucination_rate,
        instruction_following,
        jailbreak_resistance,
        factuality_score,
        rlhf_aligned,
        safety_training,
        fecha,
        row_number() over (partition by model_name_order order by fecha desc) as rn
    from src
)

select
    {{ dbt_utils.generate_surrogate_key(['d.model_name_order', 'd.fecha']) }} as id_safety,
    mid.id_model as id_modelo,
    d.toxicity_score,
    d.bias_score,
    d.refusal_rate,
    d.hallucination_rate,
    d.instruction_following,
    d.jailbreak_resistance,
    d.factuality_score,
    d.rlhf_aligned,
    d.safety_training,
    d.fecha,
    case when d.rn = 1 then true else false end as is_current
from deduped d
left join {{ ref('stg_model_union_ids') }} mid
    on mid.model_name_order = d.model_name_order
where d.rn = 1
