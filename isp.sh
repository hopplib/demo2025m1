#!/bin/bash

HQ=/etc/net/ifaces/ens19
BR=/etc/net/ifaces/ens20

# Set hostname and timezone

hostnamectl set-hostname isp.au-team.irpo
timedatectl set-timezone Asia/Yekaterinburg

apt-get install -y frr

# Cheking directories

if [ -d "$HQ" ]; then
	echo "$HQ exists"
else
	mkdir $HQ 
fi

if [ -d "$BR" ]; then
	echo "$BR exists"
else
	mkdir $BR
fi

# Making options files

cat <<EOF > /etc/net/ifaces/ens19/options
NM_CONTROLLED=no
SYSTEMD_CONTROLLED=yes
DISABLED=no
TYPE=eth
CONFIG_WIRELESS=no
BOOTPROTO=static
SYSTEMD_BOOTPROTO=static
CONFIG_IPV4=YES
EOF

cat <<EOF > /etc/net/ifaces/ens20/options
NM_CONTROLLED=no
SYSTEMD_CONTROLLED=yes
DISABLED=no
TYPE=eth
CONFIG_WIRELESS=no
BOOTPROTO=static
SYSTEMD_BOOTPROTO=static
CONFIG_IPV4=YES
EOF

# Adding ip-addresses

echo "172.16.4.2/28" > /etc/net/ifaces/ens19/ipv4address 

echo "172.16.5.2/28" > /etc/net/ifaces/ens20/ipv4address 

systemctl restart network

# Enable forwarding

sed -i '10s/.*/net.ipv4.ip_forward = 1/' /etc/net/sysctl.conf
iptables -t nat -A POSTROUTING -o ens18 -j MASQUERADE
iptables-save
