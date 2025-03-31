#!/bin/bash

NET=/etc/net/ifaces/ens19
GRE=/etc/net/ifaces/gre1

# Set hostname and timezone

hostnamectl set-hostname br-rtr.au-team.irpo
timedatectl set-timezone Asia/Yekateringburg

apt-get install -y frr

sed -i 's/ospfd=no/ospfd=yes' /etc/frr/daemons

# Configuring br network

if [ -d "$NET" ]; then
	echo "$NET exists"
else
	mkdir $NET
fi

cat <<EOF > /etc/net/ifaces/ens19/options
TYPE=eth
BOOTPROTO=static
SYSTEMD_BOOTPROTO=static
CONFIG_IPV4=yes
DISABLED=no
SYSTEMD_CONTROLLED=yes
EOF

echo "192.168.3.1/29" > /etc/net/ifaces/ens19/ipv4address

# Set GRE tunnel between hq-rtr and br-rtr

if [ -d "$GRE" ]; then
	echo "$GRE exists"
else
	mkdir $GRE
fi

cat <<EOF > /etc/net/ifaces/gre1/options
TYPE=iptun
TUNTYPE=gre
TUNREMOTE=172.16.4.1
TUNLOCAL=172.16.5.1
TUNOPTIONS='ttl 64'
EOF

echo "10.0.0.2/30" > /etc/net/ifaces/gre1/ipv4address
echo "default via 10.0.0.2" > /etc/net/ifaces/gre1/ipv4route

systemctl restart network

# Enable forwarding

sed -i '10s/.*/net.ipv4.ip_forward = 1/' /etc/net/sysctl.conf

iptables -t nat -A POSTROUTING -o ens18 -j MASQUERADE
iptables-save

# Adding user
# After script is executed you should write: passwd net_admin

useradd -d /home/net_admin net_admin
usermod -aG wheel net_admin
echo "WHEEL_USERS ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers



