{% macro clean_model_name(base_expr) %}
    lower(
      trim(
        regexp_replace(
          regexp_replace(
            {{ base_expr }},
            '-',
            ' '
          ),
          '\\s+',
          ' '
        )
      )
    )
{% endmacro %}