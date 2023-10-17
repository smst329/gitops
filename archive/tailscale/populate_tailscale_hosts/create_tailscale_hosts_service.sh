#!/bin/bash

cp tailscale_hosts.sh /usr/local/bin/tailscale_hosts.sh
cp tailscale_hosts.service /etc/systemd/system/tailscale_hosts.service

systemctl enable tailscale_hosts.service
systemctl start tailscale_hosts.service
