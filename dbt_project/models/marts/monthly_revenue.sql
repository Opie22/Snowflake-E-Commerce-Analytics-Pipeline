-- monthly_revenue.sql
-- Monthly revenue aggregates. Powers the revenue trend chart in Streamlit.

select
    date_trunc('month', purchased_at)::date  as month,
    customer_state,
    count(distinct order_id)                 as order_count,
    count(distinct customer_unique_id)       as unique_customers,
    sum(total_payment_value)                 as gross_revenue,
    avg(total_payment_value)                 as avg_order_value
from {{ ref('fct_orders') }}
where order_status = 'delivered'
group by 1, 2
order by 1, 2
