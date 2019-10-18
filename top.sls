# top.sls for mgmt1 Salt environment states

mgmt1:
  '*':
    - gandi-ddns
    - mgmt-docker-ce.volumes
    - mgmt-docker-ce
    - sackbomb
    - salt-masterless
