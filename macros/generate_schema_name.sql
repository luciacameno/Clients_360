
{#
  Override de Cívica: el nombre del esquema según dónde se ejecute.
  - Jobs de DEV y PRO (target name dev / pro): el esquema tal cual  → core
  - Jobs de CI: siempre con prefijo, para no pisar PRO          → dbt_cloud_pr_123_core
  - El IDE (target name default): prefijo personal             → dbt_lucameno_core
#}
{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    {%- set invocation_context = env_var('DBT_CLOUD_INVOCATION_CONTEXT', '') -%}

    {%- if custom_schema_name is none -%}
        {{ default_schema }}

    {%- elif invocation_context != 'ci' and target.name in ['dev', 'pro'] -%}
        {{ custom_schema_name | trim }}

    {%- else -%}
        {{ default_schema }}_{{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}