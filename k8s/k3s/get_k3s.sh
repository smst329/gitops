#! /bin/bash
set -euo pipefail

curl -sfL https://get.k3s.io | tee k3s.sh | sha256sum -c <(echo "3798b669b3ede25b2d3bfb9039a744604efb3681a351b2c1e0b01b7b05f0a434  -") && cat k3s.sh | sh - && rm k3s.sh || echo "failed hash check"
