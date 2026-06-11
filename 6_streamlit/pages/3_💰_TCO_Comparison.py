import streamlit as st
import pandas as pd
import plotly.express as px

from utils.i18n import t
from utils.queries import get_tco_comparison, get_tco_summary

st.title(t("tco"))

SCENARIOS = {
    "1M_tokens": "1M " + t("tokens"),
    "10M_tokens": "10M " + t("tokens"),
    "100M_tokens": "100M " + t("tokens"),
    "1B_tokens": "1B " + t("tokens"),
}

with st.sidebar:
    st.header(t("tco"))

    scenario = st.radio(
        t("scenario"),
        options=list(SCENARIOS.keys()),
        format_func=lambda x: SCENARIOS[x],
        index=1,
        key="tco_scenario",
    )

    with st.spinner(t("loading")):
        all_df = get_tco_comparison(scenario=scenario)

    api_providers = sorted(all_df["API_PROVEEDOR"].dropna().unique().tolist()) if not all_df.empty else []
    infra_providers = sorted(all_df["INFRA_PROVEEDOR"].dropna().unique().tolist()) if not all_df.empty else []

    sel_api = st.multiselect(
        t("api_provider"),
        options=api_providers,
        default=[],
        key="tco_api_prov",
    )

    sel_infra = st.multiselect(
        t("infra_provider"),
        options=infra_providers,
        default=[],
        key="tco_infra_prov",
    )

    st.divider()

with st.spinner(t("loading")):
    df = get_tco_comparison(
        scenario=scenario,
        api_providers=sel_api if sel_api else None,
        infra_providers=sel_infra if sel_infra else None,
    )
    summary = get_tco_summary(scenario)

if df.empty:
    st.warning(t("no_data"))
    st.stop()

col1, col2, col3, col4 = st.columns(4)
col1.metric(t("total_models"), df["MODELO_NOMBRE"].nunique())
col2.metric(
    t("cheapest_api"),
    f"{summary.get('cheapest_api_model', '—')} (${summary.get('cheapest_api_cost', 0):,.2f})",
)
col3.metric(
    t("cheapest_selfhosted"),
    f"{summary.get('cheapest_sh_gpu', '—')} (${summary.get('cheapest_sh_cost', 0):,.2f})",
)
col4.metric(t("break_even"), "Ver tabla abajo")

st.divider()

st.subheader(f"📊 {t('scenario')}: {SCENARIOS[scenario]}")

chart_data = df.groupby(["MODELO_NOMBRE", "API_PROVEEDOR"]).agg({
    "COSTO_TOTAL_API": "first",
    "COSTO_MENSUAL_ON_DEMAND": "first",
    "COSTO_MENSUAL_SPOT": "first",
    "COSTO_MENSUAL_SERVIDOR": "first",
}).reset_index()

fig = px.bar(
    chart_data,
    x="MODELO_NOMBRE",
    y=["COSTO_TOTAL_API", "COSTO_MENSUAL_ON_DEMAND", "COSTO_MENSUAL_SPOT"],
    color_discrete_map={
        "COSTO_TOTAL_API": "#1f77b4",
        "COSTO_MENSUAL_ON_DEMAND": "#ff7f0e",
        "COSTO_MENSUAL_SPOT": "#2ca02c",
    },
    labels={
        "MODELO_NOMBRE": t("model"),
        "value": t("cost"),
        "variable": "Tipo",
    },
    title="API vs On-Demand vs Spot (mensual)",
    barmode="group",
    height=500,
)
fig.update_layout(xaxis_tickangle=-45)
st.plotly_chart(fig, use_container_width=True)

st.subheader("⚖️ Ratio API / Self-Hosted")

ratio_df = df[[
    "MODELO_NOMBRE", "API_PROVEEDOR", "INFRA_PROVEEDOR",
    "RATIO_API_VS_DEDICADO", "RATIO_API_VS_ON_DEMAND", "RECOMENDACION",
]].copy()
ratio_df = ratio_df.drop_duplicates(subset=["MODELO_NOMBRE", "API_PROVEEDOR", "INFRA_PROVEEDOR"])

fig2 = px.scatter(
    ratio_df,
    x="RATIO_API_VS_ON_DEMAND",
    y="RATIO_API_VS_DEDICADO",
    color="RECOMENDACION",
    hover_data=["MODELO_NOMBRE", "API_PROVEEDOR", "INFRA_PROVEEDOR"],
    title="Ratio API vs Self-Hosted (>1 = API más cara)",
    labels={
        "RATIO_API_VS_ON_DEMAND": "API / On-Demand",
        "RATIO_API_VS_DEDICADO": "API / Dedicado",
    },
)
fig2.add_vline(x=1, line_dash="dash", line_color="gray")
fig2.add_hline(y=1, line_dash="dash", line_color="gray")
st.plotly_chart(fig2, use_container_width=True)

st.divider()

st.subheader(f"📋 {t('tco')} - Detalle")

display_cols = {
    "MODELO_NOMBRE": t("model"),
    "API_PROVEEDOR": t("api_provider"),
    "FAMILIA_NOMBRE": t("family_label"),
    "ESCENARIO": t("scenario"),
    "COSTO_TOTAL_API": t("cost") + " API",
    "GPU_NOMBRE": "GPU",
    "INFRA_PROVEEDOR": t("infra_provider"),
    "PRECIO_ON_DEMAND_HR": "Precio On-Demand/hr",
    "PRECIO_SPOT_HR": "Precio Spot/hr",
    "PRECIO_MENSUAL": "Precio Mensual",
    "NUM_GPUS": "# GPUs",
    "COSTO_MENSUAL_ON_DEMAND": "Costo On-Demand",
    "COSTO_MENSUAL_SPOT": "Costo Spot",
    "COSTO_MENSUAL_SERVIDOR": "Costo Servidor",
    "RATIO_API_VS_DEDICADO": "Ratio API/Dedicado",
    "RATIO_API_VS_ON_DEMAND": "Ratio API/On-Demand",
    "RECOMENDACION": t("recommendation"),
}

available = [c for c in display_cols if c in df.columns]
df_show = df[available].copy()
df_show.columns = [display_cols[c] for c in available]

for col in df_show.columns:
    if "Costo" in col or "Precio" in col:
        df_show[col] = df_show[col].apply(lambda x: f"${x:,.4f}" if pd.notna(x) else "—")
    elif "Ratio" in col:
        df_show[col] = df_show[col].apply(lambda x: f"{x:.2f}" if pd.notna(x) else "—")


def color_rec(val):
    if val == "API mas cara":
        return "color: red; font-weight: bold"
    elif val == "Self-hosted mas caro":
        return "color: green; font-weight: bold"
    return ""


style_df = df_show.style
if t("recommendation") in df_show.columns:
    style_df = style_df.map(color_rec, subset=[t("recommendation")])

st.dataframe(
    style_df,
    use_container_width=True,
    hide_index=True,
)

st.caption(
    f"{len(df)} combinaciones | Escenario: {SCENARIOS[scenario]} | "
    f"{len(sel_api) if sel_api else 'Todos'} API prov | "
    f"{len(sel_infra) if sel_infra else 'Todos'} Infra prov"
)