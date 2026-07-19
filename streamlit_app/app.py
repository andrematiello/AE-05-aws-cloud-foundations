"""Streamlit dashboard for AE-05, deployed on EC2, reading a CSV from S3.

Same shape as the bootcamp exercise this project rebuilds (an EC2-hosted
Streamlit app reading a CSV from S3), pointed at real AE-01 market data
instead of the tutorial's NYC Uber pickups dataset.
"""

from __future__ import annotations

import os

import pandas as pd
import streamlit as st

DATA_URL = os.environ.get(
    "MARKET_DATA_URL",
    "data/market_prices.csv",  # local fallback for `streamlit run` without S3
)

st.set_page_config(page_title="AE-05: Market Prices from S3", layout="wide")
st.title("AE-05: Market Prices, served from S3 by an EC2-hosted app")
st.caption(
    "Reads the AE-01 dimensional model's daily-price mart from an S3 CSV. "
    f"Source: {DATA_URL}"
)


@st.cache_data
def load_data(url: str) -> pd.DataFrame:
    df = pd.read_csv(url, parse_dates=["trade_date"])
    return df


data_load_state = st.text("Loading data...")
data = load_data(DATA_URL)
data_load_state.text(f"Done, {len(data):,} rows loaded.")

if st.checkbox("Show raw data"):
    st.subheader("Raw data")
    st.dataframe(data)

sectors = sorted(data["sector"].unique())
sector = st.selectbox("Sector", ["All"] + sectors)
filtered = data if sector == "All" else data[data["sector"] == sector]

tickers = sorted(filtered["ticker"].unique())
ticker = st.selectbox("Ticker", tickers)
ticker_data = filtered[filtered["ticker"] == ticker].sort_values("trade_date")

col1, col2, col3 = st.columns(3)
col1.metric("Trading days", f"{len(ticker_data):,}")
col2.metric("Latest close", f"${ticker_data['close_price'].iloc[-1]:,.2f}")
col3.metric(
    "Period return",
    f"{(ticker_data['close_price'].iloc[-1] / ticker_data['close_price'].iloc[0] - 1) * 100:.1f}%",
)

st.subheader(f"{ticker}: close price")
st.line_chart(ticker_data.set_index("trade_date")["close_price"])

st.subheader(f"{ticker}: daily volume")
st.bar_chart(ticker_data.set_index("trade_date")["volume"])
