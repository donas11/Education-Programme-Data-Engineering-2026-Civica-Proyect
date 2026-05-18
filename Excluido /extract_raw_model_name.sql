{% macro extract_raw_model_name(base_expr, part,default_expr='null') %}    case
      when position('/' in {{ base_expr }}) > 0
           then split_part({{ base_expr }}, '/', {{ part }})
      when position(':' in {{ base_expr }}) > 0
           then split_part({{ base_expr }}, ':', {{ part }})
      else {{ default_expr }}
    end
{% endmacro %}




-- with_surrogate as (
--   select
--     md5(cast(coalesce(cast(model_clean_name as TEXT), '_dbt_utils_surrogate_key_null_') || '-' || coalesce(cast(canonical_provider as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) as model_sk,
--     model_clean_name,
--     canonical_provider
--   from dedup
-- )

-- select * from with_surrogate;