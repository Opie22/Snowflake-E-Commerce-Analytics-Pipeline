-- assert_order_total_matches_payment_sum.sql
-- Singular test: verifies that the total_payment_value in fct_orders matches
-- the sum of individual payments in stg_order_payments.
-- Returns rows that FAIL (non-zero result = test failure).

with fact_totals as (
    select order_id, total_payment_value
    from {{ ref('fct_orders') }}
),
payment_totals as (
    select order_id, sum(payment_value) as payment_sum
    from {{ ref('stg_order_payments') }}
    group by 1
)

select
    f.order_id,
    f.total_payment_value,
    p.payment_sum,
    abs(f.total_payment_value - p.payment_sum) as discrepancy
from fact_totals f
join payment_totals p on f.order_id = p.order_id
where abs(f.total_payment_value - p.payment_sum) > 0.01   -- allow 1 cent rounding tolerance
