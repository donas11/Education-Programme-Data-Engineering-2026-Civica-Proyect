{% macro extract_raw_model_name(base_expr, part,default_expr='null') %}    case
      when position('/' in {{ base_expr }}) > 0
           then split_part({{ base_expr }}, '/', {{ part }})
      when position(':' in {{ base_expr }}) > 0
           then split_part({{ base_expr }}, ':', {{ part }})
      else {{ default_expr }}
    end
{% endmacro %}