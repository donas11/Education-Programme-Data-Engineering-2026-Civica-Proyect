{% macro price_to_per_unit(column) %}
    TRY_TO_NUMBER({{ column }}) / 1000000
{% endmacro %}