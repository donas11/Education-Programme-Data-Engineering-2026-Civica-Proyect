{% macro extract_canonical_model_name(base_expr, part) %}
    lower(
      trim(
        regexp_replace(    
            regexp_replace(
                regexp_replace(
                    case
                    when position('/' in {{ base_expr }}) > 0
                        then split_part({{ base_expr }}, '/', {{ part }})
                    when position(':' in {{ base_expr }}) > 0
                        then split_part({{ base_expr }}, ':', {{ part }})
                    else {{ base_expr }}
                    end,
                    '-', ' '
                ),
                '\\s+', ' '
            ),
            '~', ' '
        )
      )
    )
{% endmacro %}