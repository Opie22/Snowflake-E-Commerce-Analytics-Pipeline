-- =============================================================================
-- 01_database_warehouse.sql
-- Creates the core database, schemas, and virtual warehouse.
-- Run once as ACCOUNTADMIN (or SYSADMIN with appropriate privileges).
-- =============================================================================

USE ROLE ACCOUNTADMIN;

-- ── Virtual Warehouse ─────────────────────────────────────────────────────────
CREATE WAREHOUSE IF NOT EXISTS ECOMMERCE_WH
    WAREHOUSE_SIZE    = 'X-SMALL'
    AUTO_SUSPEND      = 60          -- suspend after 60 seconds of inactivity
    AUTO_RESUME       = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse for the Olist e-commerce pipeline';

-- ── Database ──────────────────────────────────────────────────────────────────
CREATE DATABASE IF NOT EXISTS ECOMMERCE_DB
    COMMENT = 'Olist e-commerce ELT pipeline';

-- ── Schemas ───────────────────────────────────────────────────────────────────
-- RAW: landing zone — data loaded directly from S3 via COPY INTO
CREATE SCHEMA IF NOT EXISTS ECOMMERCE_DB.RAW
    COMMENT = 'Raw tables loaded from S3 external stage';

-- ANALYTICS: dbt-managed transformation layer
CREATE SCHEMA IF NOT EXISTS ECOMMERCE_DB.ANALYTICS
    COMMENT = 'dbt staging, intermediate, and mart models';

-- CI: ephemeral schema for GitHub Actions CI runs
CREATE SCHEMA IF NOT EXISTS ECOMMERCE_DB.CI
    COMMENT = 'Ephemeral schema used by CI pipeline; can be dropped and recreated freely';

-- ── Verification ──────────────────────────────────────────────────────────────
SHOW WAREHOUSES LIKE 'ECOMMERCE_WH';
SHOW SCHEMAS IN DATABASE ECOMMERCE_DB;
