# top.sls for mgmt1 Salt environment pillar data

mgmt1:
  '*':
    - salt-masterless
    - mgmt-docker-ce
    - gandi-ddns
