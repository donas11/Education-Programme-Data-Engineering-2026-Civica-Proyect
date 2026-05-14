{{ config(
  schema = 'SILVER',
  materialized = 'view'
) }}


with 

source as (

    select * from {{ source('bronze_raw', 'seed_moneda') }}

),

moneda AS (
    SELECT
    {{ dbt_utils.generate_surrogate_key(['MONEDA']) }} AS id_moneda,
    MONEDA AS MONEDA,
    SIMBOLO,
    ABREVIATURA
  FROM source

)

select * from moneda