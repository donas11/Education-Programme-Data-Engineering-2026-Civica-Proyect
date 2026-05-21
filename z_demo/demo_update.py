"""
Demo update script - simulates data changes for snapshot testing
=================================================================
Run this AFTER the initial demo ingestion to simulate updates.
It modifies existing demo records so snapshots detect changes.

Usage:
    python z_demo/demo_update.py
    python z_demo/demo_ingest.py   # re-ingest with updated data
    dbt snapshot                    # snapshots will record the changes
"""

import pandas as pd
from pathlib import Path

DEMO_DIR = Path(__file__).resolve().parent

def main():
    # ── Update 1: Change model attributes (triggers snp_modelo) ──
    models_path = DEMO_DIR / "demo_models.csv"
    df = pd.read_csv(models_path)

    # Change context_window and release_date for demo-model-alpha
    mask = df["model_id"] == "demo-model-alpha"
    df.loc[mask, "context_window_k"] = 256  # was 128
    df.loc[mask, "release_date"] = "2026-06-01"  # was 2026-05-15
    df.loc[mask, "parameters_billion"] = 13.0  # was 7.0

    df.to_csv(models_path, index=False)
    print(f"[UPDATE] demo_models.csv: demo-model-alpha context_window 128→256, release_date updated")

    # ── Update 2: Change pricing (triggers snp_precio_modelo) ──
    pricing_path = DEMO_DIR / "demo_openrouter_models.csv"
    df2 = pd.read_csv(pricing_path)

    # Change prices for demo-model-alpha
    mask2 = df2["model_id"] == "demo-org/demo-model-alpha"
    df2.loc[mask2, "input_$/1M"] = "$1.5000"  # was $1.0000
    df2.loc[mask2, "output_$/1M"] = "$7.5000"  # was $5.0000
    df2.loc[mask2, "tipo_plan"] = "Reasoning"  # was "Reasoning + Cached"

    df2.to_csv(pricing_path, index=False)
    print(f"[UPDATE] demo_openrouter_models.csv: demo-model-alpha prices increased, plan changed")

    print()
    print("Now run: python z_demo/demo_ingest.py && dbt snapshot")
    print("Snapshots will record these changes as new versions with dbt_valid_from timestamps.")

if __name__ == "__main__":
    main()
