{% macro model_orden_nombre(base_expr) %}
  ARRAY_TO_STRING(
    ARRAY_SORT(
      STRTOK_TO_ARRAY(
        {{- clean_model_name(
              remove_parentheses_content(
                extract_canonical_model_name(base_expr, 2)
              )
           )
        -}},
        ' '
      )
    ),
    ' '
  )
{% endmacro %}