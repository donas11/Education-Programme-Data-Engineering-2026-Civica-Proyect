{% macro str_to_bool(column) %}
    IFF(LOWER({{ column }}) = 'true', TRUE, FALSE)
{% endmacro %}