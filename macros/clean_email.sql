{#
  Limpia un email tecleado a mano:
  1 quita espacios (trim )
   pasa a minúsculas (lower) 
   , corrige '@@' -> '@' y '.con' -> '.com'.
  Devuelve null si queda vacío. Conserva la ñ y las tildes.
#}
{% macro clean_email(column) %}
    nullif(
        regexp_replace(
            replace(lower(trim({{ column }})), '@@', '@'),
            '\\.con$', '.com'
        ),
        ''
    )
{% endmacro %}