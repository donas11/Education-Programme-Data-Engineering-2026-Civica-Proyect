{{ config(materialized='table') }}  

select
  model_id_raw_name,
  model_name_standard,
  
  trim(lower(
    SNOWFLAKE.CORTEX.TRY_COMPLETE(
      'llama3.1-8b',
      'Answer ONLY true or false. Is this an open source AI model? Model name: ' 
       || model_name_standard
    )
  )) as is_opensource

from {{ ref('stg_model_union') }}  