{% snapshot snp_precio_modelo %}

{{
    config(
        target_schema='SNAPSHOT',
        unique_key='id_precio_modelo',
        strategy='check',
        check_cols=['precio_por_M_entrada', 'precio_por_M_salida', 'tipo_plan']
    )
}}

select * from {{ ref('precio_modelo') }}

{% endsnapshot %}
