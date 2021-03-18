{% import_yaml '/srv/pillar/clustduct/unknown_macs' as unknown_macs %}
{# {% include '/srv/pillar/clustduct/unknown_macs' %} #}
/srv/pillar/new_mac.sls:
  file.serialize:
    - serializer: yaml
    - dataset:
        nodes:
{%- set empty_list = namespace(is_empty=true) %}
{% set has_mac = namespace(value=false) %}
{%- for node in pillar['nodes'] %}
{%- set has_mac.value = false %}
              {{node }}: 
{%- for value in pillar['nodes'][node] %}
{%- if value != 'base-ip' and value != 'ib-ip' and value != 'ipmi-ip' %}
                {{ value }}: {{ pillar['nodes'][node][value] }}
{%- if value == 'mac' %}
{%- set has_mac.value = true %}
{%- endif %}
{%- set empty_list.is_empty = false%}
{%- endif %}
{%- endfor %}
{%- if unknown_macs|length > 0  and has_mac.value == false%}
                mac: {{ unknown_macs.pop(0).split(" ")[0] }}
{%- endif %}
{%- endfor %}
{%- if empty_list.is_empty %}
              []
{%- endif %}
