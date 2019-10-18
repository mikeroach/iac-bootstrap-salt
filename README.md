# Infrastructure as Code - Management Container Host (SaltStack)

This repository is a tandem component of [Infrastructure as Code Bootstrap](https://github.com/mikeroach/iac-bootstrap) and contains:

* A combined SaltStack state and pillar tree that configures a GCP instance as a Docker host so Terraform can run containerized Jenkins-based CI-"lite"/CD pipeline-driven infrastructure supporting the [Aphorismophilia project](https://github.com/mikeroach/aphorismophilia).

* A Certificate Authority mini-PKI in [secrets/docker-tls](secrets/docker-tls) with client and server certificates for [Docker daemon TLS](https://docs.docker.com/engine/security/https/) which provides a secure communication channel for the [Infrastructure as Code Bootstrap's](https://github.com/mikeroach/iac-bootstrap) Terraform Docker provider.

* A GPG key archive for [encrypted pillar support](https://docs.saltstack.com/en/2019.2/ref/renderers/all/salt.renderers.gpg.html).

#### Consumers

* [Infrastructure as Code Bootstrap](https://github.com/mikeroach/iac-bootstrap) Terraform management host module's [salt-masterless provisioner](https://www.terraform.io/docs/provisioners/salt-masterless.html)
* Admin hosts deployed via said [IaC Bootstrap](https://github.com/mikeroach/iac-bootstrap) use this repository as a gitfs remote for ongoing management

#### Usage

Since I only use these states to manage the [Infrastructure as Code Bootstrap](https://github.com/mikeroach/iac-bootstrap) singleton environment, I apply changes manually rather than via an automated pipeline inside of that environment. I decided not to spend time on a comprehensive test process here given Salt's very limited role in the Aphorismophilia project, however I'd love to build a robust SaltStack multi-environment CI+CD pipeline as part of a separate project.

Applying all changes through this repository ensures that Git is the declarative source of truth regardless of whether the target host is newly provisioned through Terraform or already running.

1. Make desired state and pillar changes and commit to this repository. Encrypt any sensitive pillar data with e.g. ```echo "secret-squirrel" | gpg --armor --batch --trust-model always --encrypt -r saltstack@borrowingcarbon.net``` and mind the YAML indention level.
1. From a test or live instance that uses this repository as its [Salt Masterless](https://docs.saltstack.com/en/latest/topics/tutorials/quickstart.html) configuration, run ```salt-call --local state.apply test=true``` and inspect output.
1. Apply new configuration with ```salt-call --local state.apply``` .