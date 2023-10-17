#!/bin/bash
set -euo pipefail

sudo apt-get update && sudo apt-get install -y bind9
cp docker_named.conf /etc/bind/named.conf
systemctl restart named
