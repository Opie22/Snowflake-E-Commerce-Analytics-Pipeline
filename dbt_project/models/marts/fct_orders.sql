-- fct_orders.sql
-- Central fact table. One row per order.
-- Incremental: only processes orders not yet in the table.

{{
  config(
    materialized = 'incremental',
    unique_key   = 'order_id',
    on_schema_change = 'sync_all_columns'
  )
}}

with source as (
    select * from {{ ref('int_orders_enriched') }}
    {% if is_incremental() %}
    where purchased_at > (select max(purchased_at) from {{ this }})
    {% endif %}
)

select
    order_id,
    customer_id,
    customer_unique_id,
    customer_city,
    customer_state,
    order_status,
    purchased_at,
    approved_at,
    carrier_delivered_at,
    customer_delivered_at,
    estimated_delivery_at,
    total_payment_value,
    payment_count,
    payment_types,
    actual_delivery_days,
    estimated_delivery_days,
    case
        when order_status = 'delivered'
             and actual_delivery_days <= estimated_delivery_days
        then true else false
    end as delivered_on_time
from source
