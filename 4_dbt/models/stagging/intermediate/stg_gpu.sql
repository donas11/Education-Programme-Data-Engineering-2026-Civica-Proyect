{{ config(materialized='view') }}

with source as (
  select * from {{ source('bronze_raw', 'servidores') }}
),

normalized as (
  select
    {{ dbt_utils.generate_surrogate_key(['Modelo_GPU']) }} as id_gpu,
    Modelo_GPU                                             as nombre_comercial,
    Arquitectura                                           as arquitectura,
    VRAM_GB                                                as vram_gb,
    Ancho_Banda_G_Bs                                        as ancho_banda_gbs,
    TDP_W                                                  as tdp_w,
    FP16_TFLOPS                                            as fp16_tflops
  from source
)

select * from normalized