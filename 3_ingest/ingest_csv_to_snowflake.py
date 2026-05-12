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
        dataset_name="RAW",   # mismo nombre que en config.toml
    )

    resources = {
        "benchmark_scores":load_csv("Nuevo_benchmark_scores.csv"),
        "benchmarks":load_csv("Nuevo_benchmarks.csv"),      
        "llm_complete_dataset":load_csv("Nuevo_llm_complete_dataset.csv"),
        "models":load_csv("Nuevo_models.csv"), 
        "pricing":load_csv("Nuevo_pricing.csv"),
        "safety_alignment":load_csv("Nuevo_safety_alignment.csv"),                                 
        "ai_models_performance":load_csv("nuevo_ai_models_performance.csv"),        
        "llm_model_comparison_2026":load_csv("nuevo_llm-model-comparison-2026.csv"),
        
        "huggingfacemodels":load_csv("new_nuevo_hf_reliable_data_all_new.csv"),
        "openrouter_models":load_csv("initial_openrouter_models.csv"),
        "nuevo_openrouter_modelos":load_csv("initial_nuevo_openrouter_modelos.csv"),

        "proveedores":load_csv("new_nuevo_proveedores.csv"),    
        "proveedores_servidor":load_csv("new_nuevo_proveedores_servidor.csv"),
        "servidores":load_csv("new_nuevo_servidores.csv"),             
        
        
        "seed_Moneda":load_csv("seed_Moneda.csv"),
        "seed_Planes":load_csv("seed_Planes.csv"),
        "seed_Region":load_csv("seed_Region.csv")
    }

    for name, df in resources.items():
        print(f"Ingestando {name} con {len(df)} filas...")
        pipeline.run(
            df,
            table_name=name,
            write_disposition="append",  # dejamos histórico para SCD2 por encima
        )

if __name__ == "__main__":
    main()