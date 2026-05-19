SELECT
    {{ dbt_utils.generate_surrogate_key(['nombre']) }} AS id_gpu,
    Nombre_comercial
    arquitectura
    VRAM_GB
    ancho_banda_gbs
    tdp_w
    fp16_tflops
    
    provider AS proveedor,
    "API"    AS tipo_proveedor
  

  from {{source('bronze_raw', 'benchmark_scores') }}