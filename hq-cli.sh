#!/bin/bash

hostnamectl set-hostname hq-cli.au-team.irpo
timedatectl set-timezone Asia/Yekateringburg

cat <<EOF > /etc/net/ifaces/ens18.200/options
BOOTPROTO=dhcp
SYSTEMD_BOOTPROTO=dhcp4
TYPE=vlan
VID=200
HOST=ens18
EOF
