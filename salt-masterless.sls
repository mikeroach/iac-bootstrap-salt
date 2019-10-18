# salt-masterless.sls
#
# State to configure masterless Salt minions with configuration stored
# in a remote Git repository.

{% set salt_version = salt['pillar.get']('salt_version', '2019.2.0+ds-1') %}
{% set ssh_pubkey = salt['pillar.get']('ssh_pubkey') %}

# The ssh_privkey Pillar key is directly referenced by file.managed due to
# whitespace formatting issues when setting it as a Jinja variable.

# Install prerequisite packages.
ensure gitfs prerequisite packages installed:
  pkg.installed:
    - pkgs:
        - git
        - python-git

# Configure the SaltStack APT repository. The Terraform salt-masterless
# provisioner already did this, but specifying it here may simplify
# future management.
ensure SaltStack APT repository configured:
  pkgrepo.managed:
    - humanname: SaltStack APT repository
    - name: deb https://repo.saltstack.com/apt/ubuntu/18.04/amd64/2019.2 bionic main
    - file: /etc/apt/sources.list.d/saltstack.list
    - key_url: https://repo.saltstack.com/apt/ubuntu/18.04/amd64/2019.2/SALTSTACK-GPG-KEY.pub

# Ensure the salt-minion package is installed. The Terraform salt-masterless
# provisioner already did this, but specifying it here may simplify future
# management.
ensure salt-minion installed:
  pkg.installed:
    - name: salt-minion
    - version: {{ salt_version }}

# Ensure the salt-minion service is stopped and disabled.
ensure salt-minion disabled:
  service.dead:
    - name: salt-minion
    - enable: false

# Remove the default minion config file placed by the Terraform
# provisioner. I use the minion.d include directory and avoid placing
# any local configuration in the default file at SaltStack's
# recommendation (changes can be blown away by upgrades).
remove terraform provisioner bootstrap configuration:
  file.absent:
    - name: /etc/salt/minion

remove terraform provisioner default file root:
  file.absent:
    - name: /srv/salt

remove terraform provisioner default pillar root:
  file.absent:
    - name: /srv/pillar

# Manage the masterless minion configuration via include directory.
# FIXME: This is quick-and-dirty for now since I just want to use the
# Terraform provisioner ASAP. This belongs in e.g. a jinja template
# with values sourced from pillar.
manage salt-minion configuration:
  file.managed:
    - name: /etc/salt/minion.d/masterless.conf
    - contents: |
        saltenv: mgmt1
        file_client: local
        master_type: disable
        state_top_saltenv: mgmt1
        gitfs_provider: gitpython
        fileserver_backend:
          - gitfs
        gitfs_remotes:
          - https://github.com/mikeroach/iac-bootstrap-salt.git
        ext_pillar:
          - git:
            - mgmt1 https://github.com/mikeroach/iac-bootstrap-salt.git:
              - root: pillar

# Manage root SSH keypair and known_hosts that allows us to retrieve our
# masterless Salt configuration from private Github repos if needed.
install root SSH private key:
  file.managed:
    - name: /root/.ssh/id_rsa
    - mode: 400
    - makedirs: true
    - contents_pillar: ssh_privkey

install root SSH public key:
  file.managed:
    - name: /root/.ssh/id_rsa.pub
    - mode: 644
    - makedirs: true
    - contents: {{ ssh_pubkey }}

ensure github present in root SSH known_hosts:
  ssh_known_hosts:
    - present
    - user: root
    - name: github.com
    - fingerprint: 16:27:ac:a5:76:28:2d:36:63:1b:56:4d:eb:df:a6:48
    - fingerprint_hash_type: md5
    - hash_known_hosts: true
