#!/bin/bash

CLI_ARCH="amd64"
CILIUM_CLI_VERSION="v0.15.22"

sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum

curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz
echo 'c9bdf99362c16bb63ea44a214e39319d8ac1d196345792caae9665f36fe274a3  cilium-linux-amd64.tar.gz' >> cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum

sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin

rm cilium-linux-${CLI_ARCH}.tar.gz

sha256sum get_cilium.sh > cilium-linux-${CLI_ARCH}.tar.gz.sha256sum