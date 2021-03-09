/srv/tftpboot/pxelinux.cfg:
  file.directory:
    - user: root

/srv/tftpboot/pxelinux.cfg/default:
  file.touch

default-file:
  file.blockreplace:
    - name: /srv/tftpboot/pxelinux.cfg/default
    - marker_start: "#START cluster mangement DO NOT EDIT"
    - marker_end: "#END cluster mangement DO NOT EDIT"
    - append_if_not_found: True
    - backup: False
    - content: |
{%- for node in pillar['nodes'] %}
        LABEL {{ node }}
          MENU LABEL Boot as node {{ node }}
          KERNEL menu.c32
          APPEND /clustduct/clustduct_node.{{ node }}.pxe
{%- endfor %}
        LABEL reboot
          MENU LABEL Reboot
          COM32 reboot.c32

/srv/tftpboot/clustduct/:
  file.directory:
    - user: root

{% for node in pillar['nodes'] %}
/srv/tftpboot/clustduct/{{node}}.pxe:
  file.touch
replace-{{node}}.pxe:
  file.blockreplace:
    - name: /srv/tftpboot/clustduct/{{node}}.pxe
    - marker_start: "#START cluster mangement DO NOT EDIT"
    - marker_end: "#END cluster mangement DO NOT EDIT"
    - append_if_not_found: True
    - backup: False
{% if pillar['nodes'][node]['base-mac'] is defined %}
    - content: MENU TITLE {{ node }} {{ pillar['nodes'][node]['base-ip'] }} {{ pillar['nodes'][node]['base-mac'] }}
{% else %}
    - content: MENU TITLE {{ node }} {{ pillar['nodes'][node]['base-ip'] }}
{% endif %}

content-{{node}}.pxe:
  file.accumulated:
    - filename:  /srv/tftpboot/clustduct/{{node}}.pxe
    - name: pxe-generator-{{node}}
    - text: |
        PROMPT 0
        DEFAULT menu
        TIMEOUT 100
        LABEL local
          MENU LABEL Boot from local disk
          COM32 chain.c32
{%- for image in pillar['images'] %}
{%- if (pillar['nodes'][node]['image'] is defined and pillar['nodes'][node]['image'] == image|string()) or ( pillar['images'][image]['mandatory'] is defined and pillar['images'][image]['mandatory'])%} 
        LABEL {{ image }}
        {%- if pillar['images'][image]['description'] is defined %}
          MENU LABEL {{ pillar['images'][image]['description'] }}
        {%- else %}
          MENU LABEL {{ image }}
        {%- endif %} 
          KERNEL {{ pillar['images'][image]['kernel'] }}
          APPEND initrd={{ pillar['images'][image]['initrd'] }} {%- for arg in pillar['images'][image]['args'] %} {{ arg }} {%- endfor %}
{%- endif %}
{%- endfor %}
        MENU SEPERATOR
        LABEL save_reboot
          MENU LABEL Save to database and reboot
          COM32 reboot.c32
        LABEL go_back
          MENU LABEL Go to clustduct menu
          KERNEL menu.c32
          APPEND pxelinux.cfg/default
    - require_in:
      - file: replace-{{node}}.pxe
{% endfor %}

cleanup:
  file.recurse:
    - name: /srv/tftpboot/clustduct
    - source: salt://clustduct/
    - clean: True
    - require:
{%- for node in pillar['nodes'] %}
      - file: /srv/tftpboot/clustduct/{{node}}.pxe
{%- endfor %}
