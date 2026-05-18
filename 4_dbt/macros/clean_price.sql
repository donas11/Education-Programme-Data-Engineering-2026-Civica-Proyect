{% macro clean_price(column, currency_symbol='$') %}
    TRY_TO_NUMBER(REPLACE({{ column }}, '{{ currency_symbol }}', ''))
{% endmacro %}