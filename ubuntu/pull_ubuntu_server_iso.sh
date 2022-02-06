#!/bin/bash

wget https://releases.ubuntu.com/20.04.3/ubuntu-20.04.3-live-server-amd64.iso
git clone https://github.com/canonical-web-and-design/ubuntu.com.git
echo $(cat ubuntu.com/releases.yaml|grep $(sha256sum ubuntu-20.04.3-live-server-amd64.iso|cut -f1 -d " ")|xargs|cut -f2 -d " ")" ubuntu-20.04.3-live-server-amd64.iso"|sha256sum --check
sha256sum ubuntu-20.04.3-live-server-amd64.iso
echo $(cat ubuntu.com/releases.yaml|grep $(sha256sum ubuntu-20.04.3-live-server-amd64.iso|cut -f1 -d " ")|xargs|cut -f2 -d " ")" "$(cat ubuntu.com/releases.yaml|grep $(sha256sum  ubuntu-20.04.3-live-server-amd64.iso|cut -f1 -d " ")|xargs|cut -f3 -d " ")
