import requests
import csv
import os
from datetime import datetime, timezone

url = "https://openrouter.ai/api/v1/models"

response = requests.get(url)
data = response.json()["data"]


def fmt_price(v):
    """Convierte precio raw a $/1M tokens. Devuelve '0' si es gratis o vacío si no existe."""
    try:
        f = float(v or 0)
        return f"${f * 1_000_000:.4f}" if f > 0 else "0"
    except Exception:
        return ""


def fmt_date(ts):
    """Convierte timestamp Unix a fecha legible (UTC)."""
    try:
        return datetime.fromtimestamp(float(ts), tz=timezone.utc).strftime("%Y-%m-%d") if ts else ""
    except Exception:
        return ""


rows = []
for m in data:
    pricing  = m.get("pricing", {}) or {}
    provider = m.get("top_provider", {}) or {}
    params   = m.get("supported_parameters", []) or []
    arch     = m.get("architecture", {}) or {}

    # Precios en bruto (por token)
    prompt      = float(pricing.get("prompt", 0) or 0)
    completion  = float(pricing.get("completion", 0) or 0)
    reasoning   = float(pricing.get("internal_reasoning", 0) or 0)
    cache_read  = float(pricing.get("input_cache_read", 0) or 0)

    # Detección de tipo de plan
    is_free      = prompt == 0 and completion == 0
    is_reasoning = reasoning > 0 or "include_reasoning" in params
    is_cached    = cache_read > 0 or float(pricing.get("input_cache_write", 0) or 0) > 0
    is_batch     = "batch" in params
    is_moderated = provider.get("is_moderated", False)

    tipo = "Free" if is_free else ("Reasoning" if is_reasoning else "Standard")
    extras = (["Cached"] if is_cached else []) + (["Batch"] if is_batch else [])
    tipo_completo = tipo + (" + " + " + ".join(extras) if extras else "")

    rows.append({
        # Identificación
        "model_id":           m.get("id", ""),
        "name":               m.get("name", ""),
        "created":            fmt_date(m.get("created")),
        # Capacidades
        "total_context":      m.get("context_length", ""),
        "max_output":         provider.get("max_completion_tokens", ""),
        "modality":           arch.get("modality", ""),
        "tokenizer":          arch.get("tokenizer", ""),
        # Tipo de plan
        "tipo_plan":          tipo_completo,
        "es_free":            "Sí" if is_free else "No",
        "es_reasoning":       "Sí" if is_reasoning else "No",
        "es_cached":          "Sí" if is_cached else "No",
        "es_batch":           "Sí" if is_batch else "No",
        "es_moderado":        "Sí" if is_moderated else "No",
        # Precios raw (por token, para cálculos exactos)
        "input_price":        pricing.get("prompt", ""),
        "output_price":       pricing.get("completion", ""),
        "cache_read":         pricing.get("input_cache_read", ""),
        "cache_write":        pricing.get("input_cache_write", ""),
        "internal_reasoning": pricing.get("internal_reasoning", ""),
        "input_audio":        pricing.get("audio", ""),
        "input_audio_cache":  pricing.get("audio_cache", ""),
        # Precios formateados $/1M tokens (para lectura humana)
        "input_$/1M":         fmt_price(pricing.get("prompt")),
        "output_$/1M":        fmt_price(pricing.get("completion")),
        "cache_read_$/1M":    fmt_price(pricing.get("input_cache_read")),
        "cache_write_$/1M":   fmt_price(pricing.get("input_cache_write")),
        "reasoning_$/1M":     fmt_price(pricing.get("internal_reasoning")),
        # Metadata
        "knowledge_cutoff":     m.get("knowledge_cutoff", ""),
        "supported_parameters": "|".join(params),
    })

os.makedirs("output", exist_ok=True)
csv_path = "output/openrouter_models.csv"
with open(csv_path, "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=rows[0].keys(), quoting=csv.QUOTE_MINIMAL)
    writer.writeheader()
    writer.writerows(rows)

print(f"✅ CSV generado: {csv_path}  ({len(rows)} modelos, {len(rows[0])} columnas)")
