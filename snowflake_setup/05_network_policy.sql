-- =============================================================================
-- 05_network_policy.sql
-- Creates a permissive network policy required for external connections
-- (dbt Core, Python scripts, Streamlit) on Snowflake free-trial accounts.
--
-- NOTE: This allows ALL IPs (0.0.0.0/0). Fine for development/portfolio use.
-- In production, restrict to your office/VPN CIDR ranges.
--
-- Run as ACCOUNTADMIN. Only needs to be run once per account.
-- =============================================================================

USE ROLE ACCOUNTADMIN;

CREATE NETWORK POLICY IF NOT EXISTS DEV_ALLOW_ALL
    ALLOWED_IP_LIST = ('0.0.0.0/0')
    COMMENT = 'Dev policy — allows all IPs for local development and CI/CD';

ALTER ACCOUNT SET NETWORK_POLICY = DEV_ALLOW_ALL;

-- Verify
SHOW NETWORK POLICIES;
