#!/bin/bash
set -euo pipefail

while [[ -z "$(ps aux|grep tailscaled|grep -v grep)" ]]; do sleep 1; done
export TAILSCALE_IP=$(tailscale ip|head -n 1|grep -E "^100\.[0-9]+\.[0-9]+\.[0-9]+$")
while [[ -z "$TAILSCALE_IP" ]]; do sleep 1; export TAILSCALE_IP=$(tailscale ip|head -n 1|grep -E "^100\.[0-9]+\.[0-9]+\.[0-9]+$"); done

export TAILSCALE_IP=$(tailscale ip|head -n 1|grep -E "^100\.[0-9]+\.[0-9]+\.[0-9]+$");
while true; do if test -n "$TAILSCALE_IP"; then /root/go/bin/gotty --address $TAILSCALE_IP -w zsh || true; fi; sleep 3; export TAILSCALE_IP=$(tailscale ip|head -n 1|grep -E "^100\.[0-9]+\.[0-9]+\.[0-9]+$"); done
