-- customer_ltv.sql
-- Customer lifetime value segmentation.

with base as (
    select
        customer_unique_id,
        lifetime_value,
        total_orders,
        first_order_at,
        last_order_at,
        ntile(4) over (order by lifetime_value) as ltv_quartile
    from {{ ref('dim_customers') }}
    where total_orders > 0
)

select
    customer_unique_id,
    total_orders,
    lifetime_value,
    first_order_at,
    last_order_at,
    ltv_quartile,
    case ltv_quartile
        when 4 then 'High Value'
        when 3 then 'Mid-High Value'
        when 2 then 'Mid-Low Value'
        else        'Low Value'
    end as ltv_segment
from base
