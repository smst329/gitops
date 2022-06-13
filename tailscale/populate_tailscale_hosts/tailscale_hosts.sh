#!/bin/bash

while [[ -z "$(ps aux|grep tailscaled|grep -v grep)" ]]; do sleep 1; done

export TAILSCALE_IP=$(tailscale ip|head -n 1|grep -E "^100\.[0-9]+\.[0-9]+\.[0-9]+$")
while [[ -z "$TAILSCALE_IP" ]]; do sleep 1; export TAILSCALE_IP=$(tailscale ip|head -n 1|grep -E "^100\.[0-9]+\.[0-9]+\.[0-9]+$"); done

export TAILSCALE_IP=$(tailscale ip|head -n 1|grep -E "^100\.[0-9]+\.[0-9]+\.[0-9]+$");
while true; do if test -n "$TAILSCALE_IP"; then export non_tailscale_hosts=$(cat /etc/hosts|grep -vE "^100\.[0-9]+\.[0-9]+\.[0-9]+\s.+$"); export tailscale_hosts=$(tailscale status|grep -E "^100\.[0-9]+\.[0-9]+\.[0-9]+\s.+\s.+$"|awk -F' ' '{print $1, $2}'|grep -v '("")');echo "$non_tailscale_hosts" >/etc/hosts;echo "$tailscale_hosts" >> /etc/hosts; fi; sleep 5; export TAILSCALE_IP=$(tailscale ip|head -n 1|grep -E "^100\.[0-9]+\.[0-9]+\.[0-9]+$"); done
