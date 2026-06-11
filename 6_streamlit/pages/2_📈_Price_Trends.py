import streamlit as st
import pandas as pd
import plotly.express as px
from datetime import date, timedelta

from utils.i18n import t
from utils.queries import (
    get_price_trends,
    get_available_models,
    get_date_bounds,
    get_latest_prices,
)

st.title(t("price_trends"))

models_data = get_available_models()
model_options = {f"{m['MODELO_NOMBRE']} ({m['NOMBRE_PROVEEDOR']})": m['ID_MODELO'] for m in models_data}
model_names = list(model_options.keys())

min_date, max_date = get_date_bounds()
if min_date and max_date:
    min_date = pd.to_datetime(min_date).date()
    max_date = pd.to_datetime(max_date).date()
    default_start = min_date
else:
    min_date = date.today() - timedelta(days=365)
    max_date = date.today()
    default_start = max_date - timedelta(days=90)

with st.sidebar:
    st.header(t("price_trends"))

    sel_models = st.multiselect(
        t("model"),
        options=model_names,
        default=model_names[:5] if len(model_names) >= 5 else model_names,
        key="pt_models",
    )
    sel_model_ids = [model_options[m] for m in sel_models]

    st.subheader(t("date_range"))
    date_mode = st.radio(
        t("date_range"),
        options=["full", "90d", "30d", "custom"],
        format_func=lambda x: {
            "full": t("full_history"),
            "90d": t("last_90_days"),
            "30d": t("last_30_days"),
            "custom": t("custom_range"),
        }[x],
        index=1,
        key="pt_date_mode",
    )

    if date_mode == "custom":
        date_start = st.date_input("Desde", value=default_start, min_value=min_date, max_value=max_date, key="pt_start")
        date_end = st.date_input("Hasta", value=max_date, min_value=min_date, max_value=max_date, key="pt_end")
    elif date_mode == "90d":
        date_start = max_date - timedelta(days=90)
        date_end = max_date
    elif date_mode == "30d":
        date_start = max_date - timedelta(days=30)
        date_end = max_date
    else:
        date_start = min_date
        date_end = max_date

    st.divider()
    if st.button(t("loading"), disabled=True):
        pass

with st.spinner(t("loading")):
    df = get_price_trends(
        models=sel_model_ids if sel_model_ids else None,
        date_start=date_start,
        date_end=date_end,
    )

if df.empty:
    st.warning(t("no_data"))
    st.stop()

df["FECHA_VALOR"] = pd.to_datetime(df["FECHA_VALOR"])

st.subheader("📈 " + t("price_trends"))

fig = px.line(
    df,
    x="FECHA_VALOR",
    y="PRECIO_PROMEDIO",
    color="MODELO_NOMBRE",
    title=f"Precio Promedio por Modelo ({date_start} a {date_end})",
    labels={
        "FECHA_VALOR": t("date"),
        "PRECIO_PROMEDIO": t("price_avg"),
        "MODELO_NOMBRE": t("model"),
    },
    hover_data=["PRECIO_POR_M_ENTRADA", "PRECIO_POR_M_SALIDA", "PCT_CAMBIO_PROMEDIO"],
)
fig.update_layout(height=500, hovermode="x unified")
st.plotly_chart(fig, use_container_width=True)

col1, col2 = st.columns(2)

with col1:
    fig_in = px.line(
        df,
        x="FECHA_VALOR",
        y="PRECIO_POR_M_ENTRADA",
        color="MODELO_NOMBRE",
        title="Precio Entrada ($/M tokens)",
        labels={"FECHA_VALOR": t("date"), "PRECIO_POR_M_ENTRADA": t("input_price"), "MODELO_NOMBRE": t("model")},
    )
    fig_in.update_layout(height=350, hovermode="x unified")
    st.plotly_chart(fig_in, use_container_width=True)

with col2:
    fig_out = px.line(
        df,
        x="FECHA_VALOR",
        y="PRECIO_POR_M_SALIDA",
        color="MODELO_NOMBRE",
        title="Precio Salida ($/M tokens)",
        labels={"FECHA_VALOR": t("date"), "PRECIO_POR_M_SALIDA": t("output_price"), "MODELO_NOMBRE": t("model")},
    )
    fig_out.update_layout(height=350, hovermode="x unified")
    st.plotly_chart(fig_out, use_container_width=True)

st.divider()

st.subheader("📊 Últimos Precios y Cambios %")

latest = get_latest_prices(sel_model_ids if sel_model_ids else None)

if not latest.empty:
    latest = latest.sort_values("FECHA_VALOR").groupby("ID_MODELO").tail(1)
    latest = latest[["MODELO_NOMBRE", "NOMBRE_PROVEEDOR", "FECHA_VALOR", "PRECIO_POR_M_ENTRADA", "PRECIO_POR_M_SALIDA", "PRECIO_PROMEDIO", "PCT_CAMBIO_PROMEDIO"]].copy()
    latest.columns = [t("model"), t("provider_label"), t("date"), t("input_price"), t("output_price"), t("price_avg"), t("pct_change")]

    def color_pct(val):
        if pd.isna(val):
            return ""
        elif val > 0:
            return "color: red"
        elif val < 0:
            return "color: green"
        return ""

    st.dataframe(
        latest.style.map(color_pct, subset=[t("pct_change")]).format({
            t("input_price"): "${:,.4f}",
            t("output_price"): "${:,.4f}",
            t("price_avg"): "${:,.4f}",
            t("pct_change"): "{:+.2f}%",
        }),
        use_container_width=True,
        hide_index=True,
    )

st.divider()

with st.expander("📋 " + t("price_trends") + " - Datos completos"):
    display_df = df[["MODELO_NOMBRE", "NOMBRE_PROVEEDOR", "FECHA_VALOR", "PRECIO_POR_M_ENTRADA", "PRECIO_POR_M_SALIDA", "PRECIO_PROMEDIO", "PCT_CAMBIO_PROMEDIO"]].copy()
    display_df.columns = [t("model"), t("provider_label"), t("date"), t("input_price"), t("output_price"), t("price_avg"), t("pct_change")]
    display_df[t("date")] = display_df[t("date")].dt.strftime("%Y-%m-%d")

    st.dataframe(
        display_df.style.format({
            t("input_price"): "${:,.4f}",
            t("output_price"): "${:,.4f}",
            t("price_avg"): "${:,.4f}",
            t("pct_change"): "{:+.2f}%",
        }),
        use_container_width=True,
        hide_index=True,
    )

st.caption(f"{len(df)} registros | {len(sel_models)} modelos | {date_start} a {date_end}")