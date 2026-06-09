-- =============================================================================
-- 03_storage_integration.sql
-- Creates a STORAGE INTEGRATION so Snowflake can read from S3 without
-- storing AWS keys inside Snowflake. Also creates the external stage.
--
-- Prerequisites:
--   1. AWS S3 bucket already created (same region as your Snowflake account).
--   2. IAM policy with s3:GetObject, s3:ListBucket on your bucket.
--   3. You will need to grab the IAM_USER_ARN + EXTERNAL_ID from the DESC
--      INTEGRATION output and paste them into your AWS IAM trust policy.
--
-- Run as ACCOUNTADMIN.
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE ECOMMERCE_WH;

-- ── Step 1: Storage Integration ───────────────────────────────────────────────
-- Replace <YOUR_BUCKET_NAME> with your actual S3 bucket name.
CREATE STORAGE INTEGRATION IF NOT EXISTS S3_ECOMMERCE_INTEGRATION
    TYPE                      = EXTERNAL_STAGE
    STORAGE_PROVIDER          = 'S3'
    ENABLED                   = TRUE
    STORAGE_AWS_ROLE_ARN      = 'arn:aws:iam::YOUR_AWS_ACCOUNT_ID:role/snowflake-s3-role'
    STORAGE_ALLOWED_LOCATIONS = ('s3://YOUR_BUCKET_NAME/raw/');

-- ── Step 2: Retrieve ARN & External ID for the AWS Trust Policy ───────────────
-- Copy STORAGE_AWS_IAM_USER_ARN and STORAGE_AWS_EXTERNAL_ID from this output
-- and add them to the AWS IAM trust relationship for snowflake-s3-role.
DESC INTEGRATION S3_ECOMMERCE_INTEGRATION;

-- ── Step 3: Grant integration usage to LOADER role ───────────────────────────
GRANT USAGE ON INTEGRATION S3_ECOMMERCE_INTEGRATION TO ROLE LOADER;

-- ── Step 4: External Stage ────────────────────────────────────────────────────
USE ROLE LOADER;
USE DATABASE ECOMMERCE_DB;
USE SCHEMA RAW;

CREATE STAGE IF NOT EXISTS RAW.OLIST_STAGE
    STORAGE_INTEGRATION = S3_ECOMMERCE_INTEGRATION
    URL                 = 's3://YOUR_BUCKET_NAME/raw/'
    FILE_FORMAT         = (
        TYPE             = 'CSV'
        FIELD_OPTIONALLY_ENCLOSED_BY = '"'
        SKIP_HEADER      = 1
        NULL_IF          = ('NULL', 'null', '')
        EMPTY_FIELD_AS_NULL = TRUE
        DATE_FORMAT      = 'AUTO'
        TIMESTAMP_FORMAT = 'AUTO'
    )
    COMMENT = 'External stage pointing to the Olist raw CSV landing zone in S3';

-- ── Step 5: Verify the stage lists your uploaded CSVs ────────────────────────
-- Run this after uploading the Olist CSVs to S3:
-- LIST @RAW.OLIST_STAGE;
