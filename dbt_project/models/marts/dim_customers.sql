-- dim_customers.sql
-- Customer dimension with lifetime aggregates.

with customers as (
    select * from {{ ref('stg_customers') }}
),
orders as (
    select
        customer_unique_id,
        count(*)                  as total_orders,
        sum(total_payment_value)  as lifetime_value,
        min(purchased_at)         as first_order_at,
        max(purchased_at)         as last_order_at
    from {{ ref('int_orders_enriched') }}
    where order_status = 'delivered'
    group by 1
)

select
    c.customer_unique_id,
    c.zip_code,
    c.city,
    c.state,
    coalesce(o.total_orders, 0)   as total_orders,
    coalesce(o.lifetime_value, 0) as lifetime_value,
    o.first_order_at,
    o.last_order_at
from customers c
left join orders o on c.customer_unique_id = o.customer_unique_id
