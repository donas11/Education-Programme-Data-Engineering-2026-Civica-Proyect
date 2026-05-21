{% macro price_to_per_million(column) %}
    TRY_TO_NUMBER({{ column }}) * 1000000
{% endmacro %}