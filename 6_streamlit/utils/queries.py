from utils.snowflake_conn import run_query, get_schema_name


def get_reasoning_leaderboard(providers=None, families=None, min_benchmarks=1, sort_by="score_valor_reasoning"):
    schema = get_schema_name("mart")
    where_clauses = ["num_benchmarks_reasoning >= %(min_benchmarks)s"]
    params = {"min_benchmarks": min_benchmarks}

    if providers:
        placeholders = ",".join([f"%({f'p{i}'})s" for i in range(len(providers))])
        where_clauses.append(f"nombre_proveedor IN ({placeholders})")
        for i, p in enumerate(providers):
            params[f"p{i}"] = p

    if families:
        placeholders = ",".join([f"%({f'f{i}'})s" for i in range(len(families))])
        where_clauses.append(f"familia_nombre IN ({placeholders})")
        for i, f in enumerate(families):
            params[f"f{i}"] = f

    where_sql = " AND ".join(where_clauses)

    valid_sorts = {
        "score_valor_reasoning": "score_valor_reasoning DESC",
        "puntuacion_promedio_reasoning": "puntuacion_promedio_reasoning DESC",
        "precio_promedio_total": "precio_promedio_total ASC",
    }
    order_sql = valid_sorts.get(sort_by, "score_valor_reasoning DESC")

    sql = f"""
    SELECT *
    FROM {schema}.mrt_reasoning_leaderboard
    WHERE {where_sql}
    ORDER BY {order_sql}
    """
    return run_query(sql, params=params)


def get_price_trends(models=None, date_start=None, date_end=None):
    schema = get_schema_name("mart")
    where_clauses = []
    params = {}

    if models:
        placeholders = ",".join([f"%({f'm{i}'})s" for i in range(len(models))])
        where_clauses.append(f"id_modelo IN ({placeholders})")
        for i, m in enumerate(models):
            params[f"m{i}"] = m

    if date_start:
        where_clauses.append("fecha_valor >= %(date_start)s")
        params["date_start"] = date_start

    if date_end:
        where_clauses.append("fecha_valor <= %(date_end)s")
        params["date_end"] = date_end

    where_sql = " AND ".join(where_clauses) if where_clauses else "1=1"

    sql = f"""
    SELECT *
    FROM {schema}.mrt_price_trend_analysis
    WHERE {where_sql}
    ORDER BY id_modelo, fecha_valor
    """
    return run_query(sql, params=params)


def get_tco_comparison(scenario="10M_tokens", api_providers=None, infra_providers=None):
    schema = get_schema_name("mart")
    where_clauses = ["escenario = %(scenario)s"]
    params = {"scenario": scenario}

    if api_providers:
        placeholders = ",".join([f"%({f'ap{i}'})s" for i in range(len(api_providers))])
        where_clauses.append(f"api_proveedor IN ({placeholders})")
        for i, p in enumerate(api_providers):
            params[f"ap{i}"] = p

    if infra_providers:
        placeholders = ",".join([f"%({f'ip{i}'})s" for i in range(len(infra_providers))])
        where_clauses.append(f"infra_proveedor IN ({placeholders})")
        for i, p in enumerate(infra_providers):
            params[f"ip{i}"] = p

    where_sql = " AND ".join(where_clauses)

    sql = f"""
    SELECT *
    FROM {schema}.mrt_total_cost_of_ownership
    WHERE {where_sql}
    ORDER BY modelo_nombre, api_proveedor, infra_proveedor
    """
    return run_query(sql, params=params)


def get_available_providers():
    schema = get_schema_name("core")
    sql = f"""
    SELECT DISTINCT nombre_proveedor
    FROM {schema}.dim_proveedor
    WHERE nombre_proveedor IS NOT NULL
    ORDER BY nombre_proveedor
    """
    df = run_query(sql)
    return df["NOMBRE_PROVEEDOR"].tolist() if not df.empty else []


def get_available_families():
    schema = get_schema_name("core")
    sql = f"""
    SELECT DISTINCT familia_nombre
    FROM {schema}.dim_modelo
    WHERE familia_nombre IS NOT NULL
    ORDER BY familia_nombre
    """
    df = run_query(sql)
    return df["FAMILIA_NOMBRE"].tolist() if not df.empty else []


def get_available_models():
    schema = get_schema_name("mart")
    sql = f"""
    SELECT DISTINCT id_modelo, modelo_nombre, nombre_proveedor
    FROM {schema}.mrt_price_trend_analysis
    ORDER BY modelo_nombre
    """
    df = run_query(sql)
    if not df.empty:
        return df[["ID_MODELO", "MODELO_NOMBRE", "NOMBRE_PROVEEDOR"]].to_dict("records")
    return []


def get_date_bounds():
    schema = get_schema_name("mart")
    sql = f"""
    SELECT MIN(fecha_valor) as min_date, MAX(fecha_valor) as max_date
    FROM {schema}.mrt_price_trend_analysis
    """
    df = run_query(sql)
    if not df.empty:
        return df.iloc[0]["MIN_DATE"], df.iloc[0]["MAX_DATE"]
    return None, None


def get_leaderboard_kpis(providers=None, families=None, min_benchmarks=1):
    df = get_reasoning_leaderboard(providers, families, min_benchmarks)
    if df.empty:
        return {
            "total_models": 0,
            "avg_score": 0,
            "best_value": None,
            "best_performer": None,
        }

    total = len(df)
    avg_score = df["PUNTUACION_PROMEDIO_REASONING"].mean()
    best_value = df.loc[df["SCORE_VALOR_REASONING"].idxmax(), "MODELO_NOMBRE"] if "SCORE_VALOR_REASONING" in df.columns else None
    best_performer = df.loc[df["PUNTUACION_PROMEDIO_REASONING"].idxmax(), "MODELO_NOMBRE"] if "PUNTUACION_PROMEDIO_REASONING" in df.columns else None

    return {
        "total_models": total,
        "avg_score": round(avg_score, 2),
        "best_value": best_value,
        "best_performer": best_performer,
    }


def get_latest_prices(models=None):
    df = get_price_trends(models)
    if df.empty:
        return df

    latest = df.sort_values("FECHA_VALOR").groupby("ID_MODELO").tail(1)
    return latest


def get_tco_summary(scenario="10M_tokens"):
    df = get_tco_comparison(scenario)
    if df.empty:
        return {}

    cheapest_api = df.loc[df["COSTO_TOTAL_API"].idxmin()]
    cheapest_selfhosted = df.loc[df["COSTO_MENSUAL_SERVIDOR"].idxmin()]

    return {
        "cheapest_api_model": cheapest_api["MODELO_NOMBRE"],
        "cheapest_api_provider": cheapest_api["API_PROVEEDOR"],
        "cheapest_api_cost": cheapest_api["COSTO_TOTAL_API"],
        "cheapest_sh_gpu": cheapest_selfhosted["GPU_NOMBRE"],
        "cheapest_sh_provider": cheapest_selfhosted["INFRA_PROVEEDOR"],
        "cheapest_sh_cost": cheapest_selfhosted["COSTO_MENSUAL_SERVIDOR"],
    }