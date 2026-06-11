import streamlit as st
import pandas as pd
import plotly.express as px

from utils.i18n import t
from utils.queries import (
    get_reasoning_leaderboard,
    get_available_providers,
    get_available_families,
    get_leaderboard_kpis,
)

st.title(t("leaderboard"))

providers = get_available_providers()
families = get_available_families()

with st.sidebar:
    st.header(t("leaderboard"))

    sel_providers = st.multiselect(
        t("provider"),
        options=providers,
        default=[],
        key="lb_providers",
    )

    sel_families = st.multiselect(
        t("family"),
        options=families,
        default=[],
        key="lb_families",
    )

    min_bench = st.slider(
        t("min_benchmarks"),
        min_value=1,
        max_value=10,
        value=1,
        key="lb_min_bench",
    )

    sort_options = {
        "score_valor_reasoning": t("value_score"),
        "puntuacion_promedio_reasoning": t("avg_score"),
        "precio_promedio_total": t("total_price"),
    }
    sort_by = st.selectbox(
        t("sort_by"),
        options=list(sort_options.keys()),
        format_func=lambda x: sort_options[x],
        key="lb_sort",
    )
    sort_by_upper = sort_by.upper()

    st.divider()
    if st.button(t("loading"), disabled=True):
        pass

with st.spinner(t("loading")):
    df = get_reasoning_leaderboard(
        providers=sel_providers if sel_providers else None,
        families=sel_families if sel_families else None,
        min_benchmarks=min_bench,
        sort_by=sort_by,
    )

    kpis = get_leaderboard_kpis(
        providers=sel_providers if sel_providers else None,
        families=sel_families if sel_families else None,
        min_benchmarks=min_bench,
    )

if df.empty:
    st.warning(t("no_data"))
    st.stop()

col1, col2, col3, col4 = st.columns(4)
col1.metric(t("total_models"), kpis["total_models"])
col2.metric(t("avg_score_label"), kpis["avg_score"])
col3.metric(t("best_value"), kpis["best_value"] or "—")
col4.metric(t("best_performer"), kpis["best_performer"] or "—")

st.divider()

chart_df = df.head(15).copy()
chart_df = chart_df.sort_values(sort_by_upper, ascending=True)

fig = px.bar(
    chart_df,
    x=sort_by_upper,
    y="MODELO_NOMBRE",
    color="NOMBRE_PROVEEDOR",
    orientation="h",
    title=f"Top 15 por {sort_options[sort_by]}",
    labels={
        "MODELO_NOMBRE": t("model"),
        sort_by_upper: sort_options[sort_by],
        "NOMBRE_PROVEEDOR": t("provider_label"),
    },
    height=500,
)
fig.update_layout(yaxis={"categoryorder": "total ascending"})
st.plotly_chart(fig, use_container_width=True)

st.divider()

display_cols = {
    "MODELO_NOMBRE": t("model"),
    "NOMBRE_PROVEEDOR": t("provider_label"),
    "FAMILIA_NOMBRE": t("family_label"),
    "NUM_BENCHMARKS_REASONING": t("benchmarks"),
    "PUNTUACION_PROMEDIO_REASONING": t("avg_score"),
    "PUNTUACION_MAXIMA_REASONING": "Max Score",
    "PUNTUACION_MINIMA_REASONING": "Min Score",
    "PRECIO_PROMEDIO_ENTRADA": t("input_price"),
    "PRECIO_PROMEDIO_SALIDA": t("output_price"),
    "PRECIO_PROMEDIO_TOTAL": t("total_price"),
    "SCORE_VALOR_REASONING": t("value_score"),
    "RANKING_POR_RENDIMIENTO": "Rank Perf",
    "RANKING_POR_VALOR": "Rank Valor",
}

available_cols = [c for c in display_cols.keys() if c in df.columns]
df_display = df[available_cols].copy()
df_display.columns = [display_cols[c] for c in available_cols]

for col in [t("input_price"), t("output_price"), t("total_price")]:
    if col in df_display.columns:
        df_display[col] = df_display[col].apply(lambda x: f"${x:,.4f}" if pd.notna(x) else "—")

if t("value_score") in df_display.columns:
    df_display[t("value_score")] = df_display[t("value_score")].apply(lambda x: f"{x:,.4f}" if pd.notna(x) else "—")

if t("avg_score") in df_display.columns:
    df_display[t("avg_score")] = df_display[t("avg_score")].apply(lambda x: f"{x:.2f}" if pd.notna(x) else "—")

st.dataframe(
    df_display,
    use_container_width=True,
    hide_index=True,
    column_config={
        "Rank Perf": st.column_config.NumberColumn("Rank Perf", format="%d"),
        "Rank Valor": st.column_config.NumberColumn("Rank Valor", format="%d"),
    },
)

st.caption(f"{len(df)} modelos | Filtros: {len(sel_providers)} proveedores, {len(sel_families)} familias, min {min_bench} benchmarks")