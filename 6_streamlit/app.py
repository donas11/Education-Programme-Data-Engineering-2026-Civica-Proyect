import streamlit as st

from utils.i18n import init_i18n, t, LANG_OPTIONS, THEME_OPTIONS
from utils.snowflake_conn import test_connection, get_schema_name

st.set_page_config(
    page_title="LLM Analytics Dashboard",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded",
)

init_i18n()

DARK_CSS = """
<style>
[data-testid="stAppViewContainer"] { background-color: #0e1117; color: #fafafa; }
[data-testid="stSidebar"] { background-color: #262730; }
[data-testid="stHeader"] { background-color: #0e1117; }
[data-testid="stToolbar"] { background-color: #0e1117; }
.stButton>button { background-color: #1f77b4; color: white; border: none; }
.stSelectbox>div>div { background-color: #262730; color: #fafafa; }
.stMultiSelect>div>div { background-color: #262730; color: #fafafa; }
.stDataFrame { background-color: #0e1117; }
div[data-testid="stMetric"] { background-color: #262730; border: 1px solid #444; border-radius: 8px; padding: 1rem; }
div[data-testid="stMetric"] label { color: #aaa !important; }
div[data-testid="stMetric"] div { color: #fafafa !important; }
</style>
"""

LIGHT_CSS = """
<style>
[data-testid="stAppViewContainer"] { background-color: #ffffff; color: #262730; }
[data-testid="stSidebar"] { background-color: #f0f2f6; }
[data-testid="stHeader"] { background-color: #ffffff; }
.stButton>button { background-color: #1f77b4; color: white; border: none; }
</style>
"""


def apply_theme():
    theme = st.session_state.get("theme", "light")
    if theme == "dark":
        st.markdown(DARK_CSS, unsafe_allow_html=True)
    else:
        st.markdown(LIGHT_CSS, unsafe_allow_html=True)


def sidebar():
    with st.sidebar:
        st.title("📊 LLM Analytics")
        st.caption("Snowflake + dbt + Streamlit")

        st.divider()

        lang = st.selectbox(
            t("language"),
            options=list(LANG_OPTIONS.keys()),
            format_func=lambda x: LANG_OPTIONS[x],
            index=list(LANG_OPTIONS.keys()).index(st.session_state.lang),
            key="lang_selector",
        )
        if lang != st.session_state.lang:
            st.session_state.lang = lang
            st.rerun()

        theme = st.selectbox(
            t("theme"),
            options=list(THEME_OPTIONS.keys()),
            format_func=lambda x: THEME_OPTIONS[x],
            index=list(THEME_OPTIONS.keys()).index(st.session_state.theme),
            key="theme_selector",
        )
        if theme != st.session_state.theme:
            st.session_state.theme = theme
            apply_theme()
            st.rerun()

        st.divider()

        if test_connection("POST"):
            st.success(f"✅ {t('connection_ok')}: PRO_GOLD_BD_MODELOS")
        else:
            st.error(f"❌ {t('connection_error')}")

        st.caption(f"Schemas: {get_schema_name('core')}, {get_schema_name('mart')}")


apply_theme()
sidebar()

pages = [
    st.Page("pages/1_🏆_Reasoning_Leaderboard.py", title=t("leaderboard"), icon="🏆"),
    st.Page("pages/2_📈_Price_Trends.py", title=t("price_trends"), icon="📈"),
    st.Page("pages/3_💰_TCO_Comparison.py", title=t("tco"), icon="💰"),
]

pg = st.navigation(pages)
pg.run()