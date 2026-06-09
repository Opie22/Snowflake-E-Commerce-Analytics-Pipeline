-- int_order_items_with_products.sql
-- Enriches order items with product category and seller location.

with items as (
    select * from {{ ref('stg_order_items') }}
),
products as (
    select * from {{ ref('stg_products') }}
),
sellers as (
    select * from {{ ref('stg_sellers') }}
),
enriched as (
    select
        i.order_id,
        i.order_item_id,
        i.product_id,
        p.category           as product_category,
        i.seller_id,
        s.city               as seller_city,
        s.state              as seller_state,
        i.price,
        i.freight_value,
        i.price + i.freight_value as total_item_value,
        i.shipping_limit_at
    from items i
    left join products p on i.product_id = p.product_id
    left join sellers  s on i.seller_id  = s.seller_id
)

select * from enriched
