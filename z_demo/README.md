# z_demo - Demo Data for Incremental & Snapshot Testing

## Purpose
This folder contains demo CSV files and an ingestion script to demonstrate:
1. **Incremental models** (`test_benchmark`, `precio_modelo`) — only process new rows
2. **Snapshots** (`snp_modelo`, `snp_precio_modelo`) — track historical changes

## Files

| File | Maps to Bronze Table | Purpose |
|---|---|---|
| `demo_benchmark_scores.csv` | `benchmark_scores` | New scores with **future dates** (2026-06+) to trigger incremental |
| `demo_models.csv` | `models` | New models to test `snp_modelo` snapshot |
| `demo_openrouter_models.csv` | `new_nuevo_openrouter_modelos` | New pricing data to test `precio_modelo` incremental + `snp_precio_modelo` |
| `demo_ingest.py` | — | Ingestion script that loads only demo files |

## How It Works

### Incremental Logic
- `test_benchmark` filters: `fecha > (select max(fecha) from this)` → only picks up 2026-06+ dates
- `precio_modelo` filters: `fecha > (select max(fecha) from this)` → only picks up new `created` dates

### Snapshot Logic
- `snp_modelo` checks changes in: `nombre_comercial`, `context_window`, `multimodal`, `opensource`, `fecha_lanzamiento`
- `snp_precio_modelo` checks changes in: `precio_por_M_entrada`, `precio_por_M_salida`, `tipo_plan`

## Usage

```bash
# 1. Run demo ingestion (from project root)
python z_demo/demo_ingest.py

# 2. Run incremental models only
dbt run --select test_benchmark+ precio_modelo+

# 3. Run snapshots to capture state
dbt snapshot

# 4. Run tests
dbt test

# 5. To simulate an UPDATE (change existing data):
#    - Edit demo_models.csv to change context_window or release_date of an existing model
#    - Edit demo_openrouter_models.csv to change input_$/1M or output_$/1M
#    - Re-run ingestion + snapshot → snapshot will record the change as a new row with dbt_valid_to

# 6. Verify in Snowflake:
#    SELECT * FROM DEV_SILVER_BD_MODELOS.SNAPSHOT.SNP_MODELO WHERE model_name LIKE 'Demo%';
#    SELECT * FROM DEV_SILVER_BD_MODELOS.SNAPSHOT.SNP_PRECIO_MODELO WHERE id_modelo LIKE 'demo%';
```

## Demo Data Details

### benchmark_scores (14 rows)
- 3 new models: `demo-model-alpha`, `demo-model-beta`, `demo-model-gamma`
- 2 updated scores for existing models: `gpt-4o`, `claude-opus-4`
- All dates are **June-July 2026** (after existing data max of ~2026-04)

### models (3 rows)
- 3 new models with different architectures (Dense, MoE)
- Different `context_window_k` values to show variety

### openrouter_models (3 rows)
- 3 models with different plan types (Reasoning+Cached, Standard+Cached, Reasoning)
- Different pricing tiers to demonstrate snapshot detection on price changes
