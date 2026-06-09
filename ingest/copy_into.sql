-- =============================================================================
-- copy_into.sql
-- COPY INTO statements for each Olist raw table.
-- Run manually (Phase 3 baseline) or via the DAILY_LOAD_TASK (Phase 3 Task).
--
-- Assumptions:
--   • External stage @RAW.OLIST_STAGE is created (03_storage_integration.sql)
--   • Raw tables already exist; add CREATE TABLE stubs below if needed.
-- =============================================================================

USE ROLE LOADER;
USE WAREHOUSE ECOMMERCE_WH;
USE DATABASE ECOMMERCE_DB;
USE SCHEMA RAW;

-- ── Raw table definitions ─────────────────────────────────────────────────────
-- Create tables if they don't exist yet. Column types match the Olist schema.

CREATE TABLE IF NOT EXISTS RAW.OLIST_ORDERS (
    order_id                        VARCHAR,
    customer_id                     VARCHAR,
    order_status                    VARCHAR,
    order_purchase_timestamp        TIMESTAMP_NTZ,
    order_approved_at               TIMESTAMP_NTZ,
    order_delivered_carrier_date    TIMESTAMP_NTZ,
    order_delivered_customer_date   TIMESTAMP_NTZ,
    order_estimated_delivery_date   TIMESTAMP_NTZ,
    _loaded_at                      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS RAW.OLIST_ORDER_ITEMS (
    order_id            VARCHAR,
    order_item_id       NUMBER,
    product_id          VARCHAR,
    seller_id           VARCHAR,
    shipping_limit_date TIMESTAMP_NTZ,
    price               NUMBER(10, 2),
    freight_value       NUMBER(10, 2),
    _loaded_at          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS RAW.OLIST_ORDER_PAYMENTS (
    order_id              VARCHAR,
    payment_sequential    NUMBER,
    payment_type          VARCHAR,
    payment_installments  NUMBER,
    payment_value         NUMBER(10, 2),
    _loaded_at            TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS RAW.OLIST_ORDER_REVIEWS (
    review_id               VARCHAR,
    order_id                VARCHAR,
    review_score            NUMBER,
    review_comment_title    VARCHAR,
    review_comment_message  VARCHAR,
    review_creation_date    TIMESTAMP_NTZ,
    review_answer_timestamp TIMESTAMP_NTZ,
    _loaded_at              TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS RAW.OLIST_CUSTOMERS (
    customer_id              VARCHAR,
    customer_unique_id       VARCHAR,
    customer_zip_code_prefix VARCHAR,
    customer_city            VARCHAR,
    customer_state           VARCHAR,
    _loaded_at               TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS RAW.OLIST_PRODUCTS (
    product_id                  VARCHAR,
    product_category_name       VARCHAR,
    product_name_length         NUMBER,
    product_description_length  NUMBER,
    product_photos_qty          NUMBER,
    product_weight_g            NUMBER,
    product_length_cm           NUMBER,
    product_height_cm           NUMBER,
    product_width_cm            NUMBER,
    _loaded_at                  TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS RAW.OLIST_SELLERS (
    seller_id              VARCHAR,
    seller_zip_code_prefix VARCHAR,
    seller_city            VARCHAR,
    seller_state           VARCHAR,
    _loaded_at             TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS RAW.OLIST_GEOLOCATION (
    geolocation_zip_code_prefix VARCHAR,
    geolocation_lat             FLOAT,
    geolocation_lng             FLOAT,
    geolocation_city            VARCHAR,
    geolocation_state           VARCHAR,
    _loaded_at                  TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS RAW.PRODUCT_CATEGORIES (
    product_category_name            VARCHAR,
    product_category_name_english    VARCHAR,
    _loaded_at                       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ── COPY INTO statements ──────────────────────────────────────────────────────

COPY INTO RAW.OLIST_ORDERS (
    order_id, customer_id, order_status,
    order_purchase_timestamp, order_approved_at,
    order_delivered_carrier_date, order_delivered_customer_date,
    order_estimated_delivery_date
)
FROM @RAW.OLIST_STAGE/orders/
PATTERN   = '.*\.csv'
ON_ERROR  = 'CONTINUE';

COPY INTO RAW.OLIST_ORDER_ITEMS (
    order_id, order_item_id, product_id, seller_id,
    shipping_limit_date, price, freight_value
)
FROM @RAW.OLIST_STAGE/order_items/
PATTERN   = '.*\.csv'
ON_ERROR  = 'CONTINUE';

COPY INTO RAW.OLIST_ORDER_PAYMENTS (
    order_id, payment_sequential, payment_type,
    payment_installments, payment_value
)
FROM @RAW.OLIST_STAGE/order_payments/
PATTERN   = '.*\.csv'
ON_ERROR  = 'CONTINUE';

COPY INTO RAW.OLIST_ORDER_REVIEWS (
    review_id, order_id, review_score, review_comment_title,
    review_comment_message, review_creation_date, review_answer_timestamp
)
FROM @RAW.OLIST_STAGE/order_reviews/
PATTERN   = '.*\.csv'
ON_ERROR  = 'CONTINUE';

COPY INTO RAW.OLIST_CUSTOMERS (
    customer_id, customer_unique_id, customer_zip_code_prefix,
    customer_city, customer_state
)
FROM @RAW.OLIST_STAGE/customers/
PATTERN   = '.*\.csv'
ON_ERROR  = 'CONTINUE';

COPY INTO RAW.OLIST_PRODUCTS (
    product_id, product_category_name, product_name_length,
    product_description_length, product_photos_qty,
    product_weight_g, product_length_cm, product_height_cm, product_width_cm
)
FROM @RAW.OLIST_STAGE/products/
PATTERN   = '.*\.csv'
ON_ERROR  = 'CONTINUE';

COPY INTO RAW.OLIST_SELLERS (
    seller_id, seller_zip_code_prefix, seller_city, seller_state
)
FROM @RAW.OLIST_STAGE/sellers/
PATTERN   = '.*\.csv'
ON_ERROR  = 'CONTINUE';

COPY INTO RAW.OLIST_GEOLOCATION (
    geolocation_zip_code_prefix, geolocation_lat, geolocation_lng,
    geolocation_city, geolocation_state
)
FROM @RAW.OLIST_STAGE/geolocation/
PATTERN   = '.*\.csv'
ON_ERROR  = 'CONTINUE';

COPY INTO RAW.PRODUCT_CATEGORIES (
    product_category_name, product_category_name_english
)
FROM @RAW.OLIST_STAGE/product_categories/
PATTERN   = '.*\.csv'
ON_ERROR  = 'CONTINUE';

-- ── Check for rejected rows ───────────────────────────────────────────────────
-- SELECT * FROM TABLE(VALIDATE(RAW.OLIST_ORDERS, JOB_ID => '_last'));
