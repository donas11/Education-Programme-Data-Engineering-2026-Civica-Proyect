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

    {{ extract_canonical_model_name(base_expr, 1) }} as canonical_provider,
    {{ extract_canonical_model_name(base_expr, 2) }} as canonical_model_name,
    

{% endmacro %}