#!/usr/bin/env sh
set -exu

export DEBIAN_FRONTEND=noninteractive
apt update && apt install --yes jq

until jq -r -e ".bgp_neighbors" /tmp/metadata.json
do
  sleep 2
  # Refresh metadata until we have the information
  curl -o /tmp/metadata.json -fsSL https://metadata.platformequinix.com/metadata
done

jq -r ".customdata" /tmp/metadata.json > /tmp/customdata.json
