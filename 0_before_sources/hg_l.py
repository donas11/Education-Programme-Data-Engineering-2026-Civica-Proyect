import pandas as pd
from huggingface_hub import HfApi

api = HfApi()


_org_cache = {}

def is_verified_org(uploader: str) -> bool:
    if uploader in _org_cache:
        return _org_cache[uploader]  # ya lo sabemos, no llamar de nuevo
    try:
        org_info = api.get_organization(uploader)
        result = org_info is not None
    except Exception:
        result = False
    _org_cache[uploader] = result    # guardar para próximas veces
    return result


# Lista de licencias Open Source (Normalizada a minúsculas)
OS_LICENSES = [
    "mit",
    "apache-2.0",
    "cc-by",
    "bsd",
    "gpl",
    "openrail",
    "creativeml",
    "agpl",
    "afl",
    "lgpl",
]

SELF_DEPLOYABLE_LICENSES = [
    "apache-2.0",
    "mit",
    "bsd",
    "openrail",
    "creativeml",
    "llama3",
    "llama2",
    "gemma",
    "mistral",
    "mixtral",
    "gpl",
    "agpl",
]


print("Iniciando extracción con detección profunda de licencias...")

# Traemos una muestra más grande para asegurar que encontramos datos rellenados
models = api.list_models(full=True, limit=10000)

all_data = []

for m in models:
    card = m.card_data if m.card_data else {}

    # --- CAPA 1: Buscar en el YAML del card_data ---
    license_id = card.get("license")

    # --- CAPA 2: Si falla, buscar en los TAGS del modelo ---
    if not license_id and m.tags:
        # Buscamos cualquier tag que empiece por "license:"
        license_tags = [
            t.split("license:")[1] for t in m.tags if t.startswith("license:")
        ]
        if license_tags:
            license_id = license_tags[0]

    # --- CAPA 3: Si sigue fallando, buscar en la configuración base ---
    if not license_id:
        license_id = getattr(m, "license", "unknown")

    # Limpieza final del ID de licencia
    final_license = str(license_id).lower() if license_id else "unknown"

    # Verificación de fiabilidad: ¿Es realmente Open Source?
    # Buscamos si alguna de nuestras palabras clave está en la licencia encontrada
    is_open_source = (
        any(os_lic in final_license for os_lic in OS_LICENSES)
        if final_license != "unknown"
        else False
    )

    has_weights = len(m.siblings) > 0 if hasattr(m, "siblings") else False
    is_deployable = (
        any(lic in license_id for lic in SELF_DEPLOYABLE_LICENSES) and has_weights
    )

    uploader = m.id.split("/")[0] if "/" in m.id else "unknown"


    row = {
        "name": m.id,
        "category": getattr(m, "pipeline_tag", "other"),
        "slug": m.id.replace("/", "-"),
        "license": final_license,
        "openSource": is_open_source,  # Columna de fiabilidad
        "is_self_deployable": is_deployable,
        "commercial_use": not any(
            x in license_id for x in ["nc", "non-commercial", "research-only"]
        ),
        "is_local_optimized": any("gguf" in t.lower() for t in (m.tags or [])),
        "downloads": getattr(m, "downloads", 0),
        "likes": getattr(m, "likes", 0),
        "createdAt": getattr(m, "created_at", None),
        "lastModified": getattr(m, "last_modified", None),
        "pipeline_tag": getattr(m, "pipeline_tag", "unknown"),
        "library": getattr(m, "library_name", "unknown"),
        "base_model": card.get("base_model", "Original/Unknown"),
        "multimodal": any(
            t in ["vision", "image-to-text", "multimodal"] for t in (m.tags or [])
        ),
        "apiAvailable": True if getattr(m, "pipeline_tag", None) else False,
        "is_verified_org": is_verified_org(uploader),
        "is_instruct": any("instruct" in t.lower() for t in (m.tags or [])),
        "is_gguf": any("gguf" in t.lower() for t in (m.tags or [])),
        "languages": ", ".join(card.get("language", []))
        if isinstance(card.get("language"), list)
        else card.get("language", ""),
        "datasets": ", ".join(card.get("datasets", []))
        if isinstance(card.get("datasets"), list)
        else card.get("datasets", ""),
    }

    all_data.append(row)

df = pd.DataFrame(all_data)

# --- FILTRO DE CALIDAD ---
# Si quieres que tus datos sean 100% fiables para tu proyecto,
# puedes optar por quedarte solo con los que SÍ tienen licencia detectada.
# df = df[df['license'] != "unknown"]

df.to_csv("hf_reliable_data_all_new.csv", index=False)
print(
    f"Proceso finalizado. Se han detectado licencias en {len(df[df['license'] != 'unknown'])} de {len(df)} modelos."
)
