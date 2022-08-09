#!/usr/bin/env sh
set -exu

# Add BGP IP
GLOBAL_IP=$(jq -r ".globalIp" /tmp/customdata.json)

cat >>/etc/network/interfaces <<EOF
auto lo:0
iface lo:0 inet static
  address ${GLOBAL_IP}
  netmask 255.255.255.255
EOF

ifup lo:0

# Configure Routes
GATEWAY_IP=$(jq -r ".network.addresses[] | select(.public == false) | .gateway" /tmp/metadata.json)

for PEER_IP in $(jq -r ".bgp_neighbors[0].peer_ips[]" /tmp/metadata.json)
do
    ip route add ${PEER_IP} via ${GATEWAY_IP}
done

# Setup Bird
export DEBIAN_FRONTEND=noninteractive
apt update && apt install --yes python3-pip bird

cd /opt
git clone https://github.com/packethost/network-helpers.git

cd network-helpers
pip3 install jmespath
pip3 install -e .

./configure.py -r bird | tee /etc/bird/bird.conf
systemctl restart bird
