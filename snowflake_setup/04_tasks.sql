-- =============================================================================
-- 04_tasks.sql
-- Creates Snowflake Tasks to schedule the daily incremental load and a
-- Snowflake Stream on the raw orders table for change tracking.
-- Run as ACCOUNTADMIN (Tasks require EXECUTE TASK privilege).
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE ECOMMERCE_WH;
USE DATABASE ECOMMERCE_DB;
USE SCHEMA RAW;

-- ── Grant EXECUTE TASK to LOADER ─────────────────────────────────────────────
GRANT EXECUTE TASK ON ACCOUNT TO ROLE LOADER;
USE ROLE LOADER;

-- ── Stream: captures inserts/updates on raw orders ───────────────────────────
-- Create this AFTER the raw orders table exists (after first COPY INTO run).
-- CREATE STREAM IF NOT EXISTS RAW.ORDERS_STREAM
--     ON TABLE RAW.OLIST_ORDERS
--     APPEND_ONLY = TRUE          -- we only care about new rows
--     COMMENT = 'CDC stream on raw orders table for incremental loads';

-- ── Task: daily COPY INTO for all raw tables ─────────────────────────────────
-- Schedule: every day at 06:00 UTC.
-- The task calls the COPY INTO logic stored in a Snowflake stored procedure.
-- For now it runs a simple COPY INTO; replace with a CALL to a proc once
-- you've wrapped the ingest/copy_into.sql logic into a Snowflake procedure.

CREATE TASK IF NOT EXISTS RAW.DAILY_LOAD_TASK
    WAREHOUSE = ECOMMERCE_WH
    SCHEDULE  = 'USING CRON 0 6 * * * UTC'   -- 06:00 UTC daily
    COMMENT   = 'Daily incremental COPY INTO for all Olist raw tables'
AS
$$
    -- COPY INTO for orders
    COPY INTO ECOMMERCE_DB.RAW.OLIST_ORDERS
    FROM @ECOMMERCE_DB.RAW.OLIST_STAGE/orders/
    PATTERN         = '.*orders.*\.csv'
    ON_ERROR        = 'CONTINUE'
    PURGE           = FALSE;

    -- COPY INTO for order_items
    COPY INTO ECOMMERCE_DB.RAW.OLIST_ORDER_ITEMS
    FROM @ECOMMERCE_DB.RAW.OLIST_STAGE/order_items/
    PATTERN         = '.*order_items.*\.csv'
    ON_ERROR        = 'CONTINUE'
    PURGE           = FALSE;

    -- Add additional tables below as you create them...
$$;

-- ── Resume the task (tasks start in SUSPENDED state) ─────────────────────────
-- Uncomment when you are ready to activate scheduled loads:
-- ALTER TASK RAW.DAILY_LOAD_TASK RESUME;

-- ── Verification ──────────────────────────────────────────────────────────────
SHOW TASKS IN SCHEMA ECOMMERCE_DB.RAW;
-- After resuming: SELECT * FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY()) ORDER BY SCHEDULED_TIME DESC;
