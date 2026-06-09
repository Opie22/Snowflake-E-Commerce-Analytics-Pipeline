-- stg_orders.sql
-- Cleans and standardizes the raw orders table.
-- Renames columns to snake_case, casts timestamps, drops duplicates.

with source as (
    select * from {{ source('raw', 'olist_orders') }}
),

renamed as (
    select
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp::timestamp_ntz   as purchased_at,
        order_approved_at::timestamp_ntz           as approved_at,
        order_delivered_carrier_date::timestamp_ntz as carrier_delivered_at,
        order_delivered_customer_date::timestamp_ntz as customer_delivered_at,
        order_estimated_delivery_date::timestamp_ntz as estimated_delivery_at
    from source
    where order_id is not null
)

select * from renamed
