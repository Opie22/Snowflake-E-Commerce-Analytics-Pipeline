"""
dashboard/app.py
----------------
Streamlit dashboard for the Olist E-Commerce Analytics Pipeline.

Charts:
  1. Monthly revenue trend (line chart)
  2. Top 10 products by revenue (bar chart)
  3. Payment method breakdown (pie chart)
  4. Customer LTV segment distribution (bar chart)

Run:
    streamlit run dashboard/app.py

Environment variables (via .env or Streamlit secrets):
    SNOWFLAKE_ACCOUNT   — account identifier (e.g. xy12345.us-east-1)
    SNOWFLAKE_USER
    SNOWFLAKE_PASSWORD
    SNOWFLAKE_DATABASE  — ECOMMERCE_DB
    SNOWFLAKE_SCHEMA    — ANALYTICS
    SNOWFLAKE_WAREHOUSE — ECOMMERCE_WH
    SNOWFLAKE_ROLE      — REPORTER
"""

import os

import pandas as pd
import plotly.express as px
import snowflake.connector
import streamlit as st
from dotenv import load_dotenv

load_dotenv()

# ── Page config ───────────────────────────────────────────────────────────────

st.set_page_config(
    page_title="Olist E-Commerce Dashboard",
    page_icon="🛍️",
    layout="wide",
)

st.title("🛍️ Olist E-Commerce Analytics")
st.caption("Data sourced from Snowflake ANALYTICS schema via the REPORTER role.")

# ── Snowflake connection ──────────────────────────────────────────────────────

@st.cache_resource(show_spinner="Connecting to Snowflake…")
def get_connection():
    return snowflake.connector.connect(
        account   = os.environ["SNOWFLAKE_ACCOUNT"],
        user      = os.environ["SNOWFLAKE_USER"],
        password  = os.environ["SNOWFLAKE_PASSWORD"],
        database  = os.environ.get("SNOWFLAKE_DATABASE",  "ECOMMERCE_DB"),
        schema    = os.environ.get("SNOWFLAKE_SCHEMA",    "ANALYTICS"),
        warehouse = os.environ.get("SNOWFLAKE_WAREHOUSE", "ECOMMERCE_WH"),
        role      = os.environ.get("SNOWFLAKE_ROLE",      "REPORTER"),
    )


@st.cache_data(ttl=3600, show_spinner="Fetching data…")
def query(sql: str) -> pd.DataFrame:
    conn = get_connection()
    return pd.read_sql(sql, conn)


# ── KPI row ───────────────────────────────────────────────────────────────────

col1, col2, col3, col4 = st.columns(4)

totals = query("""
    select
        count(distinct order_id)          as total_orders,
        count(distinct customer_unique_id) as unique_customers,
        sum(total_payment_value)           as gross_revenue,
        avg(total_payment_value)           as avg_order_value
    from ecommerce_db.analytics.fct_orders
    where order_status = 'delivered'
""")

col1.metric("Total Orders",      f"{int(totals['TOTAL_ORDERS'][0]):,}")
col2.metric("Unique Customers",  f"{int(totals['UNIQUE_CUSTOMERS'][0]):,}")
col3.metric("Gross Revenue",     f"${totals['GROSS_REVENUE'][0]:,.0f}")
col4.metric("Avg Order Value",   f"${totals['AVG_ORDER_VALUE'][0]:,.2f}")

st.divider()

# ── Chart 1: Monthly revenue trend ───────────────────────────────────────────

st.subheader("📈 Monthly Revenue Trend")

monthly = query("""
    select
        month,
        sum(gross_revenue)    as revenue,
        sum(order_count)      as orders
    from ecommerce_db.analytics.monthly_revenue
    group by 1
    order by 1
""")
monthly.columns = monthly.columns.str.lower()

fig1 = px.line(
    monthly, x="month", y="revenue",
    labels={"month": "Month", "revenue": "Gross Revenue (BRL)"},
    template="plotly_white",
)
fig1.update_traces(line_width=2.5)
st.plotly_chart(fig1, use_container_width=True)

# ── Chart 2: Top 10 products by revenue ───────────────────────────────────────

st.subheader("🏆 Top 10 Product Categories by Revenue")

top_products = query("""
    select
        product_category,
        sum(total_item_value) as revenue
    from ecommerce_db.analytics.int_order_items_with_products
    group by 1
    order by 2 desc
    limit 10
""")
top_products.columns = top_products.columns.str.lower()

fig2 = px.bar(
    top_products, x="revenue", y="product_category",
    orientation="h",
    labels={"revenue": "Revenue (BRL)", "product_category": "Category"},
    template="plotly_white",
    color="revenue",
    color_continuous_scale="Blues",
)
fig2.update_layout(yaxis={"categoryorder": "total ascending"}, coloraxis_showscale=False)
st.plotly_chart(fig2, use_container_width=True)

# ── Charts 3 & 4: Payment mix + LTV segments ──────────────────────────────────

col_left, col_right = st.columns(2)

with col_left:
    st.subheader("💳 Payment Method Breakdown")
    payments = query("""
        select
            payment_type,
            count(*) as count
        from ecommerce_db.raw.olist_order_payments
        group by 1
        order by 2 desc
    """)
    payments.columns = payments.columns.str.lower()
    fig3 = px.pie(
        payments, names="payment_type", values="count",
        template="plotly_white",
        color_discrete_sequence=px.colors.qualitative.Pastel,
    )
    st.plotly_chart(fig3, use_container_width=True)

with col_right:
    st.subheader("👥 Customer LTV Segments")
    ltv = query("""
        select ltv_segment, count(*) as customers
        from ecommerce_db.analytics.customer_ltv
        group by 1
        order by customers desc
    """)
    ltv.columns = ltv.columns.str.lower()
    fig4 = px.bar(
        ltv, x="ltv_segment", y="customers",
        labels={"ltv_segment": "Segment", "customers": "Customers"},
        template="plotly_white",
        color="ltv_segment",
        color_discrete_sequence=px.colors.qualitative.Set2,
    )
    fig4.update_layout(showlegend=False)
    st.plotly_chart(fig4, use_container_width=True)

st.caption("Built with Streamlit + Snowflake | Data: Olist Brazilian E-Commerce")
