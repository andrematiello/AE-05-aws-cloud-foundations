#!/usr/bin/env python
"""Export a flat CSV from the AE-01 marts for the AE-05 Streamlit app.

Read-only: opens the AE-01 DuckDB warehouse in read_only mode and never
writes back to it. The output is the same shape of data the app on EC2 will
read from S3, so this script is also how the CSV in this repo was produced.
"""

from __future__ import annotations

import os
from pathlib import Path

import duckdb

DEFAULT_WAREHOUSE = (
    Path(__file__).resolve().parents[2]
    / "ae_01_modern_data_stack"
    / "warehouse.duckdb"
)
OUTPUT_PATH = Path(__file__).resolve().parents[1] / "data" / "market_prices.csv"

QUERY = """
    select
        f.trade_date,
        f.ticker,
        t.ticker_name,
        t.sector,
        t.industry,
        f.open_price,
        f.high_price,
        f.low_price,
        f.close_price,
        f.volume,
        f.daily_return
    from main.fct_daily_prices f
    join main.dim_tickers t using (ticker_key)
    order by f.ticker, f.trade_date
"""


def main() -> None:
    warehouse_path = Path(os.environ.get("AE01_DUCKDB_PATH", DEFAULT_WAREHOUSE))
    if not warehouse_path.exists():
        raise SystemExit(
            f"AE-01 warehouse not found at {warehouse_path}. "
            "Set AE01_DUCKDB_PATH to point at a built AE-01 warehouse.duckdb."
        )

    con = duckdb.connect(str(warehouse_path), read_only=True)
    df = con.execute(QUERY).fetchdf()
    con.close()

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(OUTPUT_PATH, index=False)
    print(f"Wrote {len(df)} rows to {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
