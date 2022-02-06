#!/bin/bash

cp resolved.conf /etc/systemd/resolved.conf

systemctl restart systemd-resolved.service
