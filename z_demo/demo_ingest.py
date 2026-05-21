"""
Demo ingestion script - z_demo folder
======================================
This script ingests ONLY the demo CSV files from z_demo/ to demonstrate:
  1. APPEND (incremental): benchmark_scores — new rows with future dates
  2. MERGE (upsert): models & openrouter_models — new models + updates
  3. REPLACE: static seeds (not included in demo, use main script)

Run from project root:
    python z_demo/demo_ingest.py

After ingestion, run dbt to see incremental models and snapshots pick up changes:
    dbt run --select benchmark_scores+
    dbt run --select precio_modelo+
    dbt snapshot
"""

import dlt
import pandas as pd
from pathlib import Path

DEMO_DIR = Path(__file__).resolve().parent

def load_csv(name: str) -> pd.DataFrame:
    path = DEMO_DIR / name
    df = pd.read_csv(path)
    return df

def main():
    pipeline = dlt.pipeline(
        pipeline_name="llm_csv_ingestion",
        destination="snowflake",
        dataset_name="RAW",
    )

    # ── APPEND: new benchmark scores with future dates ──
    print("=" * 60)
    print("[APPEND] Ingestando demo_benchmark_scores (incremental demo)")
    print("=" * 60)
    df = load_csv("demo_benchmark_scores.csv")
    print(f"  → {len(df)} filas nuevas con fechas posteriores a datos existentes")
    pipeline.run(df, table_name="benchmark_scores", write_disposition="append")

    # ── MERGE: new models (PK = model_id) ──
    print()
    print("=" * 60)
    print("[MERGE] Ingestando demo_models (snapshot source demo)")
    print("=" * 60)
    df = load_csv("demo_models.csv")
    print(f"  → {len(df)} modelos nuevos/actualizados (PK: model_id)")
    pipeline.run(
        df,
        table_name="models",
        write_disposition="merge",
        primary_key="model_id",
    )

    # ── MERGE: new openrouter models (PK = model_id) ──
    print()
    print("=" * 60)
    print("[MERGE] Ingestando demo_openrouter_models (pricing incremental demo)")
    print("=" * 60)
    df = load_csv("demo_openrouter_models.csv")
    print(f"  → {len(df)} modelos con precios (PK: model_id)")
    pipeline.run(
        df,
        table_name="new_nuevo_openrouter_modelos",
        write_disposition="merge",
        primary_key="model_id",
    )

    print()
    print("=" * 60)
    print("Ingestión demo completada")
    print("=" * 60)
    print()
    print("Siguientes pasos para validar:")
    print("  1. dbt run --select test_benchmark+        → incremental con fechas nuevas")
    print("  2. dbt run --select precio_modelo+          → incremental con nuevos precios")
    print("  3. dbt snapshot                             → detecta cambios en modelo y precio")
    print("  4. dbt test                                 → valida constraints")

if __name__ == "__main__":
    main()
