-- stg_order_reviews.sql
with source as (
    select * from {{ source('raw', 'olist_order_reviews') }}
),
renamed as (
    select
        review_id,
        order_id,
        review_score,
        review_comment_title   as comment_title,
        review_comment_message as comment_message,
        review_creation_date::timestamp_ntz   as review_created_at,
        review_answer_timestamp::timestamp_ntz as review_answered_at
    from source
    where review_id is not null
)
select * from renamed
