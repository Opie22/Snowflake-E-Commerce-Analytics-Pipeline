{% macro current_timestamp_utc() %}
    convert_timezone('UTC', current_timestamp())::timestamp_ntz
{% endmacro %}
