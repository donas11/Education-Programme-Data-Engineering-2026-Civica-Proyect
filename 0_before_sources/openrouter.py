import requests
import csv

url = "https://openrouter.ai/api/v1/models"

response = requests.get(url)
data = response.json()["data"]

with open("openrouter_models.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f, delimiter=",", quoting=csv.QUOTE_MINIMAL)

    # Cabecera
    writer.writerow([
        "model_id",
        "name",
        "total_context",
        "max_output",
        "input_price",
        "output_price",
        "cache_read",
        "cache_write",
        "input_audio",
        "input_audio_cache"
    ])

    for m in data:
        pricing = m.get("pricing", {})
        provider = m.get("top_provider", {})

        writer.writerow([
            m.get("id"),
            m.get("name"),
            m.get("context_length"),
            provider.get("max_completion_tokens"),
            pricing.get("prompt"),
            pricing.get("completion"),
            pricing.get("input_cache_read"),
            pricing.get("input_cache_write"),
            # audio no siempre está presente
            pricing.get("audio", ""),
            pricing.get("audio_cache", "")
        ])

print("CSV generado: openrouter_models.csv")