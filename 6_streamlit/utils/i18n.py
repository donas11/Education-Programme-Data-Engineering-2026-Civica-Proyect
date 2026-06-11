import streamlit as st

TRANSLATIONS = {
    "es": {
        "app_title": "LLM Analytics Dashboard",
        "leaderboard": "🏆 Clasificación Razonamiento",
        "price_trends": "📈 Tendencias de Precio",
        "tco": "💰 Comparación TCO",
        "language": "Idioma",
        "theme": "Tema",
        "provider": "Proveedor",
        "family": "Familia",
        "min_benchmarks": "Mín. benchmarks",
        "sort_by": "Ordenar por",
        "value_score": "Score Valor",
        "avg_score": "Score Promedio",
        "date_range": "Rango de fechas",
        "scenario": "Escenario",
        "api_provider": "Proveedor API",
        "infra_provider": "Proveedor Infra",
        "recommendation": "Recomendación",
        "loading": "Cargando...",
        "no_data": "Sin datos disponibles",
        "full_history": "Historial completo",
        "last_90_days": "Últimos 90 días",
        "last_30_days": "Últimos 30 días",
        "custom_range": "Rango personalizado",
        "total_models": "Total Modelos",
        "avg_score_label": "Score Promedio",
        "best_value": "Mejor Valor",
        "best_performer": "Mejor Rendimiento",
        "price_avg": "Precio Promedio",
        "pct_change": "Cambio %",
        "cheapest_api": "API Más Barata",
        "cheapest_selfhosted": "Self-hosted Más Barato",
        "break_even": "Punto Equilibrio",
        "tokens": "Tokens",
        "cost": "Costo",
        "ratio": "Ratio",
        "model": "Modelo",
        "rank": "Ranking",
        "score": "Score",
        "provider_label": "Proveedor",
        "family_label": "Familia",
        "benchmarks": "Benchmarks",
        "input_price": "Precio Entrada",
        "output_price": "Precio Salida",
        "total_price": "Precio Total",
        "date": "Fecha",
        "connection_ok": "Conectado",
        "connection_error": "Error conexión",
        "dark_mode": "Modo Oscuro",
        "light_mode": "Modo Claro",
    },
    "en": {
        "app_title": "LLM Analytics Dashboard",
        "leaderboard": "🏆 Reasoning Leaderboard",
        "price_trends": "📈 Price Trends",
        "tco": "💰 TCO Comparison",
        "language": "Language",
        "theme": "Theme",
        "provider": "Provider",
        "family": "Family",
        "min_benchmarks": "Min. Benchmarks",
        "sort_by": "Sort by",
        "value_score": "Value Score",
        "avg_score": "Avg Score",
        "date_range": "Date Range",
        "scenario": "Scenario",
        "api_provider": "API Provider",
        "infra_provider": "Infra Provider",
        "recommendation": "Recommendation",
        "loading": "Loading...",
        "no_data": "No data available",
        "full_history": "Full History",
        "last_90_days": "Last 90 Days",
        "last_30_days": "Last 30 Days",
        "custom_range": "Custom Range",
        "total_models": "Total Models",
        "avg_score_label": "Avg Score",
        "best_value": "Best Value",
        "best_performer": "Best Performer",
        "price_avg": "Avg Price",
        "pct_change": "Change %",
        "cheapest_api": "Cheapest API",
        "cheapest_selfhosted": "Cheapest Self-hosted",
        "break_even": "Break-even",
        "tokens": "Tokens",
        "cost": "Cost",
        "ratio": "Ratio",
        "model": "Model",
        "rank": "Rank",
        "score": "Score",
        "provider_label": "Provider",
        "family_label": "Family",
        "benchmarks": "Benchmarks",
        "input_price": "Input Price",
        "output_price": "Output Price",
        "total_price": "Total Price",
        "date": "Date",
        "connection_ok": "Connected",
        "connection_error": "Connection Error",
        "dark_mode": "Dark Mode",
        "light_mode": "Light Mode",
    }
}

LANG_OPTIONS = {
    "es": "🇪🇸 Español",
    "en": "🇺🇸 English",
}

THEME_OPTIONS = {
    "light": "☀️ Light",
    "dark": "🌙 Dark",
}


def t(key: str) -> str:
    """Get translation for current language."""
    lang = st.session_state.get("lang", "es")
    return TRANSLATIONS.get(lang, TRANSLATIONS["es"]).get(key, key)


def init_i18n():
    """Initialize i18n session state."""
    if "lang" not in st.session_state:
        st.session_state.lang = "es"
    if "theme" not in st.session_state:
        st.session_state.theme = "light"