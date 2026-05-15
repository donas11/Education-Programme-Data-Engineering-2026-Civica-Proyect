{% macro normalize_model_name(model_id, model_name) %}

  {% set base_expr = "coalesce(" ~ model_id ~ ", " ~ model_name ~ ")" %}

    -- full normalizado
    lower(
      trim(
        regexp_replace(
          {{ base_expr }},
          '\\s+',
          ' '
        )
      )
    ) as raw_full,

    -- proveedor bruto según / o :
    {{ extract_raw_model_name(base_expr, 1, 'null') }} as raw_provider_part,
    
    -- modelo bruto según / o :
    {{ extract_raw_model_name(base_expr, 2, base_expr) }} as raw_model_part,
    
    -- proveedor canónico
    {{ extract_canonical_model_name(base_expr, 1) }} as canonical_provider,

    -- nombre canónico (modelo) sin proveedor
    {{ extract_canonical_model_name(base_expr, 2) }} as canonical_model_name,
    
    regexp_substr(
      {{ base_expr }},
      '\\(([^)]*)\\)'
    ) as extra_parenthesis

{% endmacro %}