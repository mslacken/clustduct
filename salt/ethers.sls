ethers-custer-management:
  file.blockreplace:
    - name: /etc/ethers
    - marker_start: "#START cluster mangement DO NOT EDIT"
    - marker_end: "#END cluster mangement DO NOT EDIT"
    - append_if_not_found: True

ethers-generated-list:
  file.accumulated:
    - filename: /etc/ethers
    - name: ethers-genrator
    - text: |
{%- for node in pillar['nodes'] %}
{%- if pillar['nodes'][node]['base-mac'] is defined %}
         {{ pillar['nodes'][node]['base-mac'] }} {{ pillar['nodes'][node]['base-ip'] }}
{%- endif %}
{%- endfor %}
    - require_in:
      - file: ethers-custer-management
