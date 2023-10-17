#!/bin/bash

export TAILSCALE_WEB_IP=$(tailscale ip|head -n 1|grep -E "^100\.[0-9]+\.[0-9]+\.[0-9]+$")
while [[ -z "$TAILSCALE_WEB_IP" ]]; do sleep 1; export TAILSCALE_WEB_IP=$(tailscale ip|head -n 1|grep -E "^100\.[0-9]+\.[0-9]+\.[0-9]+$"); done

export TAILSCALE_WEB_IP=$(tailscale ip|head -n 1|grep -E "^100\.[0-9]+\.[0-9]+\.[0-9]+$")
while true; do if test -n "$TAILSCALE_WEB_IP"; then tailscale web --listen $TAILSCALE_WEB_IP:8000; fi; sleep 3; export TAILSCALE_WEB_IP=$(tailscale ip|head -n 1|grep -E "^100\.[0-9]+\.[0-9]+\.[0-9]+$"); done
