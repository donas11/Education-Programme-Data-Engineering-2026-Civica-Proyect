import streamlit as st
import pandas as pd
from snowflake.connector import connect
from typing import Optional


@st.cache_resource
def get_connection(env: str) -> connect:
    """Create and cache Snowflake connection per environment."""
    secrets = st.secrets[f"snowflake_{env.lower()}"]
    return connect(
        user=secrets["user"],
        password=secrets["password"],
        account=secrets["account"],
        warehouse=secrets["warehouse"],
        role=secrets["role"],
        database=secrets["database"],
    )


@st.cache_data(ttl=300, show_spinner="Consultando Snowflake...")
def run_query(sql: str, env: str = "POST", params: dict | None = None) -> pd.DataFrame:
    """Execute query and return DataFrame. Cached for 5 minutes."""
    conn = get_connection(env)
    cur = conn.cursor()
    try:
        if params:
            cur.execute(sql, params)
        else:
            cur.execute(sql)
        return cur.fetch_pandas_all()
    finally:
        cur.close()


@st.cache_data(ttl=300)
def get_table_list(env: str = "POST", schema: str = "PUBLIC_GOLD_MART") -> pd.DataFrame:
    """Get list of tables in a schema."""
    database = st.secrets[f"snowflake_{env.lower()}"]["database"]
    sql = f"""
    SELECT TABLE_NAME
    FROM {database}.INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = '{schema}'
    ORDER BY TABLE_NAME
    """
    return run_query(sql, env)


def test_connection(env: str = "POST") -> bool:
    """Test if connection works."""
    try:
        df = run_query("SELECT CURRENT_VERSION() AS VERSION", env)
        return not df.empty
    except Exception:
        return False


SCHEMAS = {
    "core": "PUBLIC_GOLD_CORE",
    "mart": "PUBLIC_GOLD_MART",
}


def get_schema_name(layer: str) -> str:
    """Get schema name for layer: 'core' or 'mart'."""
    return SCHEMAS.get(layer, "PUBLIC_GOLD_MART")