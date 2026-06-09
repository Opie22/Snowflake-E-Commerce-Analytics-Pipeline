-- =============================================================================
-- generate_schema_name.sql
-- Override dbt's default schema-naming behavior.
--
-- Default dbt behavior: target_schema + "_" + custom_schema
--   e.g. ANALYTICS + staging → ANALYTICS_STAGING  ← doesn't exist
--
-- This override: use the custom schema name exactly as written.
--   e.g. staging → STAGING
--        analytics → ANALYTICS   (the schema that already exists)
--
-- When no custom schema is set (custom_schema_name is none), fall back to
-- the profile's target schema (ANALYTICS).
-- =============================================================================

{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
