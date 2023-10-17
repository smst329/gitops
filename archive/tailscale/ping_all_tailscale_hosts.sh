#!/bin/bash

for i in $(tailscale status); do if test -n "$(echo $i|grep -E 100\.[0-9]+\.[0-9]+\.[0-9]+$)"; then echo -e "Pinging: $i\n"$(tailscale ping -c 1 --verbose $i 2>&1)"\n"; fi; done
tailscale status
