{# Comment #}
base-network:
  dns_suffix: suse.cluster
{%set base_ip = '192.168.0.0' %}
{%set base_ip_list = base_ip.split('.') %}
  base: {{base_ip_list[0] ~ '.' ~ base_ip_list[1] ~ '.' ~ base_ip_list[2] ~ '.' ~ base_ip_list[3] }} 
  gateway: 192.168.0.1
  
{% set nr_nodes_compute = 10 %}
{% set offset = 10 %}
nodes:
{% for i in range(1,nr_nodes_compute+1) %}
  compute-{{'%03i' % i }}:
    base-ip: {{base_ip_list[0] ~ '.' ~ base_ip_list[1] ~ '.' ~ base_ip_list[2] ~ '.' ~ (base_ip_list[3]|int + i + offset)}} 
{% endfor %}
include:
  - mac
{#  - ignore_missing: True #}
