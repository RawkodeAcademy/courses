#!/usr/bin/env bash
set -euxo pipefail

systemctl enable teleport
systemctl restart teleport
