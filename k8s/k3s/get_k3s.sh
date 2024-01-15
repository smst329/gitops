#! /bin/bash
set -euo pipefail

export GITHUB_URL="https://raw.githubusercontent.com/k3s-io/k3s"
export COMMIT_HASH="19fd7e38f674bddaa4571373d767c48bc52867f0"

sha256sum -c get_k3s.sh.sha256 || exit 1

echo 'bd16f2905a364da5e9d18ff7624408a49b24c91f136045d97c3000c4a26acf58  install.sh.sha256' >> get_k3s.sh.sha256
curl -sfL $GITHUB_URL/$COMMIT_HASH/install.sh.sha256sum > install.sh.sha256
sha256sum -c get_k3s.sh.sha256 || exit 1

cat install.sh.sha256 >> get_k3s.sh.sha256

curl -sfL $GITHUB_URL/$COMMIT_HASH/install.sh > install.sh
sha256sum -c get_k3s.sh.sha256 || exit 1

INSTALL_K3S_VERSION="$INSTALL_K3S_VERSION" INSTALL_K3S_SKIP_START=true INSTALL_K3S_SKIP_ENABLE=true cat install.sh | INSTALL_K3S_SKIP_START=true INSTALL_K3S_SKIP_ENABLE=true INSTALL_K3S_VERSION="$INSTALL_K3S_VERSION" sh - || exit 1

rm -f install.sh
rm -f install.sh.sha256
sha256sum get_k3s.sh > get_k3s.sh.sha256
