# gandi-ddns.sls

# Register our ephemeral external IP address to DNS hostname.

{% set ddns_domain = salt['pillar.get']('ddns_domain', 'example.com') %}
{% set ddns_hostname = salt['pillar.get']('ddns_hostname', 'example-hostname') %}
{% set gandi_api_key = salt['pillar.get']('gandi_api_key') %}

ensure DDNS oneshot service configured:
  file.managed:
    - name: /etc/systemd/system/gandi-ddns.service
    - makedirs: true
    - contents: |
        [Unit]
        Description=Register our ephemeral external IP address to DNS hostname.
        
        [Service]
        ExecStart=/bin/sh -c "IP=`curl -s ifconfig.co` ; curl -sX PUT -H \"Content-Type: application/json\" -H \"X-Api-Key: {{ gandi_api_key }}\" -d \"{\\\"rrset_ttl\\\": 300, \\\"rrset_values\\\": [\\\"$IP\\\"]}\"  https://dns.api.gandi.net/api/v5/domains/{{ ddns_domain }}/records/{{ ddns_hostname }}/A"
        Type=oneshot
        RemainAfterExit=yes
        
        [Install]
        WantedBy=multi-user.target

ensure DDNS oneshot service enabled:
  service.enabled:
    - require:
        - ensure DDNS oneshot service configured
    - name: gandi-ddns

ensure DDNS oneshot service running:
  service.running:
    - require:
        - ensure DDNS oneshot service enabled
    - name: gandi-ddns
