{% snapshot snp_modelo %}

{{
    config(
        target_schema='SNAPSHOT',
        unique_key='id_modelo',
        strategy='check',
        check_cols=['nombre_comercial', 'context_window', 'multimodal', 'opensource', 'fecha_lanzamiento']
    )
}}

select
    id_modelo,
    nombre_comercial,
    id_proveedor,
    id_familia,
    context_window,
    multimodal,
    opensource,
    fecha_lanzamiento
from {{ ref('modelo') }}

{% endsnapshot %}
