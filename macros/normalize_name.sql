{#
  Normaliza un nombre para comparar cuentas (regla R1a):
  minúsculas, sin tildes, ñ -> n y un solo espacio entre palabras.
 
#}
{% macro normalize_name(column) %}
    lower(
        regexp_replace(
            trim(
                translate(
                    {{ column }},
                    'áéíóúàèìòùäëïöüâêîôûñçÁÉÍÓÚÀÈÌÒÙÄËÏÖÜÂÊÎÔÛÑÇ',
                    'aeiouaeiouaeiouaeiouncAEIOUAEIOUAEIOUAEIOUNC'
                )
            ),
            '\\s+', ' '
        )
    )
{% endmacro %}