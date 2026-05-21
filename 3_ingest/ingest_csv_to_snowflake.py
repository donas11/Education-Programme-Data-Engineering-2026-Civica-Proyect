import dlt
import pandas as pd
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parents[1] / "1_data"

def load_csv(name: str) -> pd.DataFrame:
    path = DATA_DIR / name
    df = pd.read_csv(path)
    return df

def main():
    pipeline = dlt.pipeline(
        pipeline_name="llm_csv_ingestion",
        destination="snowflake",
        dataset_name="RAW",
    )

    # ── APPEND: hechos históricos que se acumulan ──
    append_tables = {
        "benchmark_scores": "Nuevo_benchmark_scores.csv",
    }

    # ── MERGE: catálogos que se actualizan (PK = clave primaria) ──
    merge_tables = {
        "benchmarks": ("Nuevo_benchmarks.csv", "benchmark_id"),
        "models": ("Nuevo_models.csv", "model_id"),
        "ai_models_performance": ("nuevo_ai_models_performance.csv", "Model"),
        "safety_alignment": ("Nuevo_safety_alignment.csv", "model_id"),
        "llm_model_comparison_2026": ("nuevo_llm-model-comparison-2026.csv", "Model"),
        "llm_complete_dataset": ("Nuevo_llm_complete_dataset.csv", "model_name"),
        "huggingface_models": ("new_nuevo_hf_reliable_data_all_new.csv", "model_id"),
        "openrouter_models": ("initial_openrouter_models.csv", "id"),
        "nuevo_openrouter_modelos": ("initial_nuevo_openrouter_modelos.csv", "id"),
        "new_nuevo_openrouter_modelos": ("New_nuevo_openrouter_models.csv", "model_id"),
        "proveedores": ("new_nuevo_proveedores.csv", "proveedor"),
        "proveedores_servidor": ("new_nuevo_proveedores_servidor.csv", ["Proveedor", "Modelo_Servidor"]),
        "servidores": ("new_nuevo_servidores.csv", "Modelo_GPU"),
    }

    # ── REPLACE: seeds estáticos que se refrescan completos ──
    replace_tables = {
        "seed_Moneda": "seed_Moneda.csv",
        "seed_Planes": "seed_Planes.csv",
        "seed_Region": "seed_Region.csv",
    }

    # ── Ejecutar APPEND ──
    for name, csv_file in append_tables.items():
        df = load_csv(csv_file)
        print(f"[APPEND] Ingestando {name} con {len(df)} filas...")
        pipeline.run(
            df,
            table_name=name,
            write_disposition="append",
        )

    # ── Ejecutar MERGE ──
    for name, (csv_file, primary_key) in merge_tables.items():
        df = load_csv(csv_file)
        print(f"[MERGE] Ingestando {name} con {len(df)} filas (PK: {primary_key})...")
        pipeline.run(
            df,
            table_name=name,
            write_disposition="merge",
            primary_key=primary_key,
        )

    # ── Ejecutar REPLACE ──
    for name, csv_file in replace_tables.items():
        df = load_csv(csv_file)
        print(f"[REPLACE] Ingestando {name} con {len(df)} filas...")
        pipeline.run(
            df,
            table_name=name,
            write_disposition="replace",
        )

if __name__ == "__main__":
    main()
