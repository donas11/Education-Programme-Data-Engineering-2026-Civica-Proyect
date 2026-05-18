{% macro remove_parentheses_content(base_expr) %}
  regexp_replace(
    {{ base_expr }},
    '\\(([^)]*)\\)',
    ''
  )
{% endmacro %}