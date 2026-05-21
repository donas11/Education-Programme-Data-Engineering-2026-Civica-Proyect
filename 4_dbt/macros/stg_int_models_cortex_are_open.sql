{% macro is_open_source_model(base_expr) %}
    trim(lower(
    SNOWFLAKE.CORTEX.TRY_COMPLETE(
      'llama3.1-8b',
      'Answer ONLY true or false. Is this an open source AI model? Model name: ' 
       || {{ base_expr }}
    )
  ))
{% endmacro %}
