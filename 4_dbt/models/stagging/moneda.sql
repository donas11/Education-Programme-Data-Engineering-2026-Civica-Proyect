{{ config(
  materialized = 'view'
) }}

with src as (
    select *
    from {{ source('bronze_raw', 'seed_moneda') }}
),

MONEDA AS(
  SELECT DISTINCT
    {{ dbt_utils.generate_surrogate_key(['Moneda']) }} AS id_moneda,
    Moneda as moneda,
    Simbolo	as simbolo,
    Abreviatura as abreviatura
  FROM src
)

SELECT * FROM moneda