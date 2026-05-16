{% macro normalize_model_from_expr(base_expr) %}

    lower(
      trim(
        regexp_replace(
          {{ base_expr }},
          '\\s+',
          ' '
        )
      )
    ) as raw_full,

    {{ extract_raw_model_name(base_expr, 1, 'null') }} as raw_provider_part,
    {{ extract_raw_model_name(base_expr, 2, base_expr) }} as raw_model_part,
    {{ extract_canonical_model_name(base_expr, 1) }} as canonical_provider,
    {{ extract_canonical_model_name(base_expr, 2) }} as canonical_model_name,
    regexp_substr({{ base_expr }}, '\\(([^)]*)\\)') as extra_parenthesis

{% endmacro %}