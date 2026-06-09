-- stg_order_items.sql
with source as (
    select * from {{ source('raw', 'olist_order_items') }}
),
renamed as (
    select
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date::timestamp_ntz as shipping_limit_at,
        price::numeric(10,2)              as price,
        freight_value::numeric(10,2)      as freight_value
    from source
    where order_id is not null
)
select * from renamed
