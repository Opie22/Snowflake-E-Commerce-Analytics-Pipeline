-- int_orders_enriched.sql
-- Joins orders with customers and aggregated payment totals.
-- Used by fct_orders and customer_ltv marts.

with orders as (
    select * from {{ ref('stg_orders') }}
),
customers as (
    select * from {{ ref('stg_customers') }}
),
payments as (
    select
        order_id,
        sum(payment_value) as total_payment_value,
        count(*)           as payment_count,
        listagg(payment_type, ', ') within group (order by payment_sequential)
            as payment_types
    from {{ ref('stg_order_payments') }}
    group by 1
),
enriched as (
    select
        o.order_id,
        o.customer_id,
        c.customer_unique_id,
        c.city                    as customer_city,
        c.state                   as customer_state,
        o.order_status,
        o.purchased_at,
        o.approved_at,
        o.carrier_delivered_at,
        o.customer_delivered_at,
        o.estimated_delivery_at,
        coalesce(p.total_payment_value, 0) as total_payment_value,
        coalesce(p.payment_count, 0)       as payment_count,
        coalesce(p.payment_types, 'none')  as payment_types,
        datediff('day', o.purchased_at, o.customer_delivered_at)
            as actual_delivery_days,
        datediff('day', o.purchased_at, o.estimated_delivery_at)
            as estimated_delivery_days
    from orders o
    left join customers c on o.customer_id = c.customer_id
    left join payments  p on o.order_id    = p.order_id
)

select * from enriched
