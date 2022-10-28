#!/usr/bin/env bash
set -euxo pipefail

cat > /etc/teleport.yaml <<EOCAT
teleport:
  data_dir: /var/lib/teleport
auth_service:
  enabled: true
  listen_addr: 0.0.0.0:3025
  cluster_name: rawkode-academy
ssh_service:
  enabled: true

proxy_service:
  enabled: true
  web_listen_addr: ":443"
  listen_addr: 0.0.0.0:3023
  kube_listen_addr: 0.0.0.0:3026
  tunnel_listen_addr: 0.0.0.0:3024
EOCAT

