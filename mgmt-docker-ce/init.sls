# mgmt-docker-ce/init.sls
#
# Simple state to ensure Docker CE is installed from upstream repository
# per instructions at https://docs.docker.com/install/linux/docker-ce/ubuntu/
# and configured to host our build & infrastructure management tools.

{% set docker_ce_version = salt['pillar.get']('docker_versions:docker_ce') %}
{% set docker_ce_cli_version = salt['pillar.get']('docker_versions:docker_ce_cli') %}
{% set containerd_io_version = salt['pillar.get']('docker_versions:containerd_io') %}

# The following Pillar keys are directly referenced by file.managed:
# docker_tlskey
# docker_tlscrt
# docker_tlsca

# Install prerequisite packages.
ensure Docker CE prerequisite packages installed:
  pkg.installed:
    - pkgs:
        - apt-transport-https
        - ca-certificates
        - curl
        - gnupg-agent
        - software-properties-common
    - require:
      - ensure Docker LVM logical volume mounted

# Configure the Docker CE APT repository.
ensure Docker CE APT repository configured:
  pkgrepo.managed:
    - require:
        - ensure Docker CE prerequisite packages installed
    - humanname: Docker CE APT Repository
    - name: deb https://download.docker.com/linux/ubuntu {{ grains['oscodename'] }} stable
    - file: /etc/apt/sources.list.d/docker-ce.list
    - keyid: 0EBFCD88
    - keyserver: ha.pool.sks-keyservers.net

# Deploy certificates needed for TLS.
install Docker TLS key:
  file.managed:
    - name: /etc/docker/server.key
    - mode: 400
    - makedirs: true
    - contents_pillar: docker_tlskey

install Docker TLS cert:
  file.managed:
    - name: /etc/docker/server.crt
    - makedirs: true
    - contents_pillar: docker_tlscrt

install Docker TLS CA:
  file.managed:
    - name: /etc/docker/ca.crt
    - makedirs: true
    - contents_pillar: docker_tlsca

# Install Docker CE packages with specified package versions available in the upstream repo.
# Also enable TLS and remote access via systemd override file.
ensure Docker CE packages installed and configured:
  pkg.installed:
    - require:
        - ensure Docker CE APT repository configured
    - pkgs:
        - docker-ce: {{ docker_ce_version }}
        - docker-ce-cli: {{ docker_ce_cli_version }}
        - containerd.io: {{ containerd_io_version }}
    - hold: true
  file.managed:
    - name: /etc/systemd/system/docker.service.d/override.conf
    - makedirs: true
    - contents: |
        [Service]
        ExecStart=
        ExecStart=/usr/bin/dockerd --data-root /mnt/docker_volumes --tlsverify --tlscacert /etc/docker/ca.crt --tlscert /etc/docker/server.crt --tlskey /etc/docker/server.key -H fd:// -H tcp://0.0.0.0:2376
    - require:
      - install Docker TLS key
      - install Docker TLS cert
      - install Docker TLS CA
  service.running:
    - name: docker
    - watch:
        - file: /etc/systemd/system/docker.service.d/override.conf
