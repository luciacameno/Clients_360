{#
  Limpia un teléfono español tecleado en caja:
  deja solo dígitos y quita el prefijo 0034 o 34.
  '+34 699 000 123', '699-000-123' y '0034699000123' -> '699000123'
#}
{% macro clean_phone(column) %}
    {%- set digits = "regexp_replace(" ~ column ~ ", '[^0-9]', '')" -%}
    nullif(
        case
            when {{ digits }} like '0034%' then substr({{ digits }}, 5)
            when {{ digits }} like '34%' and length({{ digits }}) = 11 then substr({{ digits }}, 3)
            else {{ digits }}
        end,
        ''
    )
{% endmacro %}