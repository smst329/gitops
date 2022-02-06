#!/bin/bash

mkdir -p /etc/docker
# append because would rather have failed docker start OR ignored parameter than overwrite another config
cat daemon.json >> /etc/docker/daemon.json
