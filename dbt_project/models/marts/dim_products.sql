-- dim_products.sql
-- Product dimension with sales aggregates.

with products as (
    select * from {{ ref('stg_products') }}
),
item_stats as (
    select
        product_id,
        count(distinct order_id) as total_orders,
        sum(price)               as total_revenue,
        avg(price)               as avg_price
    from {{ ref('int_order_items_with_products') }}
    group by 1
)

select
    p.product_id,
    p.category,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    coalesce(s.total_orders, 0)   as total_orders,
    coalesce(s.total_revenue, 0)  as total_revenue,
    coalesce(s.avg_price, 0)      as avg_price
from products p
left join item_stats s on p.product_id = s.product_id
