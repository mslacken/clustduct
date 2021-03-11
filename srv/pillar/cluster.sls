{# Comment #}
{% set base_ip = '192.168.0.0' %}
{% set gateway = '192.168.0.1' %}
{% set local_dns = 'cluster.suse' %} 
{% set nr_nodes_compute = 10 %}
{% set name_prefix = 'compute-' %}
{% set offset = 10 %}
{% set dynamic_offset = 200 %}
{% set dynamic_range = 40 %}
{% set base_ip_list = base_ip.split('.') %}
base-network:
  base_ip: {{base_ip_list[0] ~ '.' ~ base_ip_list[1] ~ '.' ~ base_ip_list[2] ~ '.' ~ base_ip_list[3] }} 
  local_dns : {{ local_dns }}
  dynamic_start: {{base_ip_list[0] ~ '.' ~ base_ip_list[1] ~ '.' ~ base_ip_list[2] ~ '.' ~ (base_ip_list[3]|int + dynamic_offset )}}
  dynamic_end:  {{base_ip_list[0] ~ '.' ~ base_ip_list[1] ~ '.' ~ base_ip_list[2] ~ '.' ~ (base_ip_list[3]|int + dynamic_offset + dynamic_range)}}
  gateway:  {{ gateway }}
nodes:
{% for i in range(1,nr_nodes_compute+1) %}
  {{ name_prefix ~ '%03i' % i }}:
    base-ip: {{base_ip_list[0] ~ '.' ~ base_ip_list[1] ~ '.' ~ base_ip_list[2] ~ '.' ~ (base_ip_list[3]|int + i + offset)}} 
{% endfor %}
include:
  - mac
{#  - ignore_missing: True #}
