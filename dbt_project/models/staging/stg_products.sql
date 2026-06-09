-- stg_products.sql
with source as (
    select * from {{ source('raw', 'olist_products') }}
),
categories as (
    select * from {{ source('raw', 'product_categories') }}
),
renamed as (
    select
        p.product_id,
        coalesce(c.product_category_name_english, p.product_category_name) as category,
        p.product_name_length,
        p.product_description_length,
        p.product_photos_qty,
        p.product_weight_g,
        p.product_length_cm,
        p.product_height_cm,
        p.product_width_cm
    from source p
    left join categories c on p.product_category_name = c.product_category_name
    where p.product_id is not null
)
select * from renamed
