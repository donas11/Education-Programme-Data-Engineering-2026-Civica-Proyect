{% macro clean_price(column, currency_symbol='$') %}
    TRY_TO_NUMBER(
        NULLIF(
            REPLACE({{ column }}, '{{ currency_symbol }}', ''),
            '—'
        )
    )
{% endmacro %}