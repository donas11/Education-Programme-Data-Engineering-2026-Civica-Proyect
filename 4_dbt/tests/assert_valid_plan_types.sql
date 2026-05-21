with invalid_planes as (
  select id_plan_precio, tipo_plan
  from {{ ref('plan_precio') }}
  where tipo_plan not in ('Free', 'Standard', 'Reasoning', 'Cached', 'Batch')
)

select * from invalid_planes
