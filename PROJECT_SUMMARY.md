# Civica Project — LLM Analytics Data Pipeline

## Arquitectura Medallion

```
┌─────────────────────────────────────────────────────────────────────┐
│                        BRONZE (RAW)                                 │
│  DEV_BRONZE_BD_MODELOS.RAW                                          │
│  CSVs crudos ingestados con dlt — sin transformación                │
├─────────────────────────────────────────────────────────────────────┤
│                        SILVER (STAGING + MODELS)                    │
│  DEV_SILVER_BD_MODELOS.STAGING  → vistas intermedias (stg_*)        │
│  DEV_SILVER_BD_MODELOS.SILVER   → vistas limpias (modelo, precio)   │
│  DEV_SILVER_BD_MODELOS.SNAPSHOT → SCD2 histórico (snp_*)            │
├─────────────────────────────────────────────────────────────────────┤
│                        GOLD (CORE + MARTS)                          │
│  DEV_GOLD_BD_MODELOS.GOLD_CORE  → dimensiones puras + hechos        │
│  DEV_GOLD_BD_MODELOS.GOLD_MART  → marts analíticos de negocio       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Tecnologías

| Tecnología | Uso |
|---|---|
| **GitHub Actions** | CI/CD — ingesta automática al hacer push a ramas DEV/PRE/PRO |
| **dlt (data load tool)** | Ingesta CSV → Snowflake con 3 write dispositions (append, merge, replace) |
| **dbt** | Transformación SQL — staging, silver, gold, snapshots, tests |
| **Snowflake** | Data warehouse — 3 entornos (DEV/PRE/PRO) × 3 capas (Bronze/Silver/Gold) |
| **Power BI** | Visualización — conecta a las tablas Gold para dashboards |

---

## Ingesta dlt (`3_ingest/ingest_csv_to_snowflake.py`)

Pipeline: `llm_csv_ingestion` → Dataset: `RAW`

### APPEND (acumula filas nuevas)

| Tabla Bronze | Archivo CSV |
|---|---|
| `benchmark_scores` | `Nuevo_benchmark_scores.csv` |

### MERGE (upsert por primary key)

| Tabla Bronze | Archivo CSV | Primary Key |
|---|---|---|
| `benchmarks` | `Nuevo_benchmarks.csv` | `benchmark_id` |
| `models` | `Nuevo_models.csv` | `model_id` |
| `ai_models_performance` | `nuevo_ai_models_performance.csv` | `Model` |
| `safety_alignment` | `Nuevo_safety_alignment.csv` | `model_id` |
| `llm_model_comparison_2026` | `nuevo_llm-model-comparison-2026.csv` | `Model` |
| `llm_complete_dataset` | `Nuevo_llm_complete_dataset.csv` | `model_name` |
| `huggingface_models` | `new_nuevo_hf_reliable_data_all_new.csv` | `model_id` |
| `openrouter_models` | `initial_openrouter_models.csv` | `id` |
| `nuevo_openrouter_modelos` | `initial_nuevo_openrouter_modelos.csv` | `id` |
| `new_nuevo_openrouter_modelos` | `New_nuevo_openrouter_models.csv` | `model_id` |
| `proveedores` | `new_nuevo_proveedores.csv` | `proveedor` |
| `proveedores_servidor` | `new_nuevo_proveedores_servidor.csv` | `[Proveedor, Modelo_Servidor]` |
| `servidores` | `new_nuevo_servidores.csv` | `Modelo_GPU` |

### REPLACE (reemplazo completo)

| Tabla Bronze | Archivo CSV |
|---|---|
| `seed_Moneda` | `seed_Moneda.csv` |
| `seed_Planes` | `seed_Planes.csv` |
| `seed_Region` | `seed_Region.csv` |

---

## Modelos Incrementales (dbt)

### `test_benchmark` → `DEV_SILVER_BD_MODELOS.SILVER.TEST_BENCHMARK`

```sql
materialized = 'incremental'
unique_key   = 'id_test'
on_schema_change = 'append_new_columns'

-- Condición incremental:
WHERE fecha > (SELECT COALESCE(MAX(fecha), '1900-01-01') FROM {{ this }})
```

Solo procesa scores con `evaluation_date` posterior a la fecha máxima ya cargada.

### `precio_modelo` → `DEV_SILVER_BD_MODELOS.SILVER.PRECIO_MODELO`

```sql
materialized = 'incremental'
unique_key   = 'id_precio_modelo'
on_schema_change = 'append_new_columns'

-- Condición incremental:
WHERE fecha > (SELECT COALESCE(MAX(fecha), '1900-01-01') FROM {{ this }})
```

Solo procesa precios con `created` posterior a la fecha máxima ya cargada.

---

## Snapshots (SCD2)

### `snp_modelo` → `DEV_SILVER_BD_MODELOS.SNAPSHOT.SNP_MODELO`

```sql
strategy   = 'check'
unique_key = 'id_modelo'
check_cols = ['nombre_comercial', 'context_window', 'multimodal', 'opensource', 'fecha_lanzamiento']
```

Fuente: `{{ ref('modelo') }}`
Detecta cambios en nombre, ventana de contexto, multimodalidad, open source o fecha de lanzamiento.

### `snp_precio_modelo` → `DEV_SILVER_BD_MODELOS.SNAPSHOT.SNP_PRECIO_MODELO`

```sql
strategy   = 'check'
unique_key = 'id_precio_modelo'
check_cols = ['precio_por_M_entrada', 'precio_por_M_salida', 'tipo_plan']
```

Fuente: `{{ ref('precio_modelo') }}`
Detecta cambios en precio de entrada, precio de salida o tipo de plan.

---

## Roles y Usuarios en Snowflake

### Roles

| Rol | Propósito | Acceso |
|---|---|---|
| `DEV_ROLE_INGEST` | Ingesta dlt en DEV | `DEV_BRONZE_BD_MODELOS.RAW` |
| `PRE_ROLE_INGEST` | Ingesta dlt en PRE | `PRE_BRONZE_BD_MODELOS.RAW` |
| `PRO_ROLE_INGEST` | Ingesta dlt en PRO | `PRO_BRONZE_BD_MODELOS.RAW` |
| `DEV_ROLE_TRANSFORM` | Transformación dbt en DEV | `DEV_BRONZE_BD_MODELOS`, `DEV_SILVER_BD_MODELOS`, `DEV_GOLD_BD_MODELOS` |
| `PRE_ROLE_TRANSFORM` | Transformación dbt en PRE | `PRE_BRONZE_BD_MODELOS`, `PRE_SILVER_BD_MODELOS`, `PRE_GOLD_BD_MODELOS` |
| `PRO_ROLE_TRANSFORM` | Transformación dbt en PRO | `PRO_BRONZE_BD_MODELOS`, `PRO_SILVER_BD_MODELOS`, `PRO_GOLD_BD_MODELOS` |

### Usuarios

| Usuario | Rol asignado | Uso |
|---|---|---|
| `USR_DLT_PDE` | `DEV_ROLE_INGEST` | Ingesta dlt → DEV |
| `USR_DLT_PRE_PDE` | `PRE_ROLE_INGEST` | Ingesta dlt → PRE |
| `USR_DLT_PRO_PDE` | `PRO_ROLE_INGEST` | Ingesta dlt → PRO |
| `USR_DBT_PDE` | `DEV_ROLE_TRANSFORM` | Transformación dbt → DEV |
| `USR_DBT_PRE_PDE` | `DEV_ROLE_TRANSFORM` | Transformación dbt → PRE |
| `USR_DBT_PRO_PDE` | `PRO_ROLE_TRANSFORM` | Transformación dbt → PRO |

Todos los usuarios usan el warehouse `PROYECTDE` (auto-suspend: 60s).

---

## CI/CD — GitHub Actions

| Workflow | Trigger Branch | Secrets |
|---|---|---|
| `ingest_dev.yml` | `push → DEV` + `workflow_dispatch` | `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`, `SNOWFLAKE_DATABASE`, `SNOWFLAKE_ACCOUNT_HOST`, `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_ROLE` |
| `ingest_pre.yml` | `push → PRE` + `workflow_dispatch` | Mismos secrets con sufijo `_PRE` |
| `ingest_pro.yml` | `push → PRO` + `workflow_dispatch` | Mismos secrets con sufijo `_PRO` |

Path filter: solo se ejecuta si cambian `1_data/**`, `3_ingest/**`, `requirements.txt` o el propio workflow.

---

## Estructura dbt (`4_dbt/`)

```
Civica_project/
├── models/
│   ├── stagging/
│   │   ├── intermediate/     → STAGING schema (vistas)
│   │   │   ├── stg_modelo.sql
│   │   │   ├── stg_servidor.sql
│   │   │   ├── stg_gpu.sql
│   │   │   ├── stg_proveedor.sql
│   │   │   ├── stg_planes.sql
│   │   │   ├── stg_model_union_ids.sql
│   │   │   └── ...
│   │   ├── modelo.sql        → SILVER schema (vista)
│   │   ├── precio_modelo.sql → SILVER (incremental)
│   │   ├── test_benchmark.sql→ SILVER (incremental)
│   │   ├── proveedor.sql
│   │   ├── benchmark.sql
│   │   └── ...
│   └── marts/
│       ├── dimensions/       → GOLD_CORE (tablas)
│       │   ├── dim_fecha.sql
│       │   ├── dim_modelo.sql
│       │   ├── dim_proveedor.sql
│       │   ├── dim_region.sql
│       │   ├── dim_plan.sql
│       │   └── dim_benchmark.sql
│       ├── facts/            → GOLD_CORE (tablas)
│       │   ├── fct_precio.sql
│       │   └── fct_benchmark.sql
│       └── marts/            → GOLD_MART (tablas)
│           ├── mrt_infraestructura.sql
│           ├── mrt_model_value_score.sql
│           ├── mrt_price_trend_analysis.sql
│           ├── mrt_reasoning_leaderboard.sql
│           ├── mrt_api_vs_selfhosted.sql
│           ├── mrt_provider_market_analysis.sql
│           └── mrt_total_cost_of_ownership.sql
├── snapshots/
│   ├── snp_modelo.sql
│   └── snp_precio_modelo.sql
├── macros/                   → funciones SQL reutilizables
├── seeds/                    → datos estáticos
├── dbt_project.yml
├── packages.yml              → dbt_date, dbt_utils, dbt_expectations
└── profiles.yml              → conexión Snowflake (local)
```

---

## Capa Gold — Star Schema

### GOLD_CORE (dimensiones puras + hechos)

| Tabla | Tipo | Descripción |
|---|---|---|
| `dim_fecha` | Dimensión | Calendario generado con dbt_date (2020-2031) |
| `dim_modelo` | Dimensión | Modelos de IA (sin agregados) |
| `dim_proveedor` | Dimensión | Proveedores deduplicados por nombre normalizado |
| `dim_region` | Dimensión | Regiones geográficas |
| `dim_plan` | Dimensión | Planes tarifarios (Free, Standard, Reasoning, Cached, Batch) |
| `dim_benchmark` | Dimensión | Catálogo de benchmarks |
| `fct_precio` | Hecho | Precios por modelo × plan × fecha |
| `fct_benchmark` | Hecho | Scores de benchmark por modelo × test × fecha |

### GOLD_MART (marts analíticos)

| Tabla | Descripción |
|---|---|
| `mrt_infraestructura` | Catálogo de GPUs y servidores |
| `mrt_model_value_score` | Relación calidad-precio de modelos |
| `mrt_price_trend_analysis` | Análisis de tendencias de precios |
| `mrt_reasoning_leaderboard` | Ranking de modelos reasoning |
| `mrt_api_vs_selfhosted` | Comparativa API vs self-hosted |
| `mrt_provider_market_analysis` | Análisis de mercado por proveedor |
| `mrt_total_cost_of_ownership` | Coste total de propiedad por infraestructura |

---

## Comandos principales

```bash
# Ingesta local
python 3_ingest/ingest_csv_to_snowflake.py

# dbt (desde 4_dbt/)
dbt run              # construir todos los modelos
dbt test             # ejecutar tests
dbt build            # run + test
dbt snapshot         # ejecutar snapshots SCD2
dbt run --select test_benchmark+ precio_modelo+  # solo incrementales
```
