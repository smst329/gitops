#!/bin/bash
set -euo pipefail

./pull_ubuntu_server_iso.sh

export TAILSCALE_IP=$(tailscale ip|head -n 1|grep -E "^100\.[0-9]+\.[0-9]+\.[0-9]+$")
while [[ -z "$TAILSCALE_IP" ]]; do sleep 1; export TAILSCALE_IP=$(tailscale ip|head -n 1|grep -E "^100\.[0-9]+\.[0-9]+\.[0-9]+$"); done

truncate -s 400G $PWD/image.sparse

/usr/bin/qemu-system-x86_64 -enable-kvm -machine type=pc,accel=kvm -usbdevice tablet -m 16384 -smp $((3*$(nproc)/4)) -boot d -cdrom $PWD/ubuntu-20.04.3-live-server-amd64.iso -drive file=$PWD/image.sparse,index=0,media=disk,format=raw,if=virtio,cache=none -nic user,hostfwd=tcp:$TAILSCALE_IP:10022-0.0.0.0:22 -vga std -vnc $TAILSCALE_IP:0,password=on -monitor stdio
