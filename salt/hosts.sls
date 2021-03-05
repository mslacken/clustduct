hosts-custer-management:
  file.blockreplace:
    - name: /etc/hosts
    - marker_start: "#START cluster mangement DO NOT EDIT"
    - marker_end: "#END cluster mangement DO NOT EDIT"
    - append_if_not_found: True

host-generated-list:
  file.accumulated:
    - filename: /etc/hosts
    - name: hosts-genrator
    - text: |
{% for node in pillar['nodes'] %}
         {{ pillar['nodes'][node]['base-ip'] }} {{node}} {{ node ~ '.' ~ pillar['base-network']['dns_suffix'] }}
{% endfor %}
    - require_in:
      - file: hosts-custer-management
