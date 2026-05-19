SELECT
    {{ dbt_utils.generate_surrogate_key(['nombre']) }} AS id_servidor,
    Nombre
    tipo
    num_gpus
    VRAM_total
    RAM_GB
    precio_ondemand_hr
    precio_spot_hr
    precio_mensual
    egress_fees_gb
    REF (GPU)
    REF (PROVEEDOR)
    provider AS proveedor,
    "API"    AS tipo_proveedor
  

  from {{source('bronze_raw', 'benchmark_scores') }}