{% import_yaml '/srv/pillar/clustduct/unknown_macs' as unknown_macs %}
{# {% include '/srv/pillar/clustduct/unknown_macs' %} #}
/srv/pillar/new_macs.sls:
  file.serialize:
    - serializer: yaml
    - dataset:
        nodes:
{%- set empty_list = namespace(is_empty=true) %}
{%- for node in pillar['nodes'] %}
{# {%- if pillar['nodes'][node]['mac'] is defined or pillar['nodes'][node]['mac'] is defined or unknown_macs.size > 0%} #}
{%- if pillar['nodes'][node]['mac'] is defined or pillar['nodes'][node]['image'] is defined %}
            {{  node }}:
{%- if pillar['nodes'][node]['mac'] is defined %}
              base-mac: {{ pillar['nodes'][node]['mac'] }} 
{%- set empty_list.is_empty = false%}
{%- endif %}
{%- if pillar['nodes'][node]['image'] is defined %}
              image: {{ pillar['nodes'][node]['image'] }}
{%- set empty_list.is_empty = false%}
{%- endif %}
{%- endif %}
{%- endfor %}
{%- if empty_list.is_empty %}
              []
{%- endif %}
{#
{%- for mac in unknown_macs %}
        {{ mac }}
{%- endfor %}
#}
