#!/bin/bash

NET=/etc/net/ifaces/ens19
BRIDGE=/etc/net/ifaces/br0
SRV=/etc/net/ifaces/ens19.100
CLI=/etc/net/ifaces/ens19.200
NINE=/etc/net/ifaces/ens19.999
GRE=/etc/net/ifaces/gre1


# Set hostname and timezone

hostnamectl set-hostname hq-rtr.au-team.irpo
timedatectl set-timezone Asia/Yekaterinburg

apt-get install -y frr dhcp-server openvswitch
systemctl enable --now openvswitch

# Enable frr

sed -i 's/ospfd=no/ospfd=yes' /etc/frr/daemons
systemctl restart frr

# Configuring interface

if [ -d "$NET" ]; then
	echo "$NET exists"
else
	mkdir $NET
fi

cat <<EOF > /etc/net/ifaces/ens19/options
TYPE=eth
CONFIG_WIRELESS=no
DISABLED=no
BOOTPROTO=static
SYSTEMD_BOOTPROTO=static
CONFIG_IPV4=yes
NM_CONTROLLED=no
SYSTEMD_CONTROLLED=no
EOF

# Configuring vlan 100

if [ -d "$SRV" ]; then
	echo "$SRV exists"
else
	mkdir $SRV
fi

cat <<EOF > /etc/net/ifaces/ens19.100/options
BOOTPROTO=static
TYPE=ovsport
VID=100
CONFIG_WIRELESS=no
CONFIG_IPV4=yes
BRIDGE=br0
EOF

echo "192.168.100.1/29" > /etc/net/ifaces/ens19.100/ipv4address

# Configuring vlan 200

if [ -d "$CLI" ]; then
	echo "$CLI exists"
else
	mkdir $CLI
fi

cat <<EOF > /etc/net/ifaces/ens19.200/options
BOOTPROTO=static
TYPE=ovsport
VID=200
CONFIG_WIRELESS=no
CONFIG_IPV4=yes
BRIDGE=br0
EOF

echo "192.168.200.1/29" > /etc/net/ifaces/ens19.200/ipv4address

# Configuring vlan 999

if [ -d "$NINE" ]; then
	echo "$NINE exists"
else
	mkdir $NINE
fi

cat <<EOF > /etc/net/ifaces/ens19.999/options
BOOTPROTO=static
TYPE=ovsport
VID=999
CONFIG_WIRELESS=no
CONFIG_IPV4=yes
BRIDGE=br0
EOF

echo "192.168.99.1/29" > /etc/net/ifaces/ens19.999/ipv4address

# Set bridge for VLANs

if [ -d "$BRIDGE" ]; then
	echo "$BRIDGE exists"
else
	mkdir $BRIDGE
fi

cat <<EOF > /etc/net/ifaces/br0/options
TYPE=ovsbr
ONBOOT=yes
BOOTPROTO=static
CONFIG_IPV4=yes
HOST='ens19'
EOF

# Set GRE tunnel between hq-rtr and br-rtr

if [ -d "$GRE" ]; then
	echo "$GRE exists"
else
	mkdir $GRE
fi

cat <<EOF > /etc/net/ifaces/gre1/options
TYPE=iptun
TUNTYPE=gre
TUNREMOTE=172.16.5.1
TUNLOCAL=172.16.4.1
TUNOPTIONS='ttl 64'
EOF

echo "10.0.0.1/30" > /etc/net/ifaces/gre1/ipv4address
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

# Configuring DHCP-server

cat << EOF > /etc/dhcp/dhcpd/dhcpd.conf.sample
subnet 192.168.200.0 netmask 255.255.255.248 {
	option routers 					192.168.200.1;
	option subnet-mask				255.255.255.248;

	option domain-name				"au-team.irpo";
	option domain-name-servers		        192.168.100.2;

	range dynamic-bootp 192.168.200.3 192.168.200.6;
	default-lease-time 21600;
	max-lease-time 43200;
}
EOF

cp /etc/dhcp/dhcpd.conf.sample /etc/dhcp/dhcpd.conf

sed -i '3s/.*/DHCPDARGS = ens19.200/' /etc/sysconfig/dhcpd

systemctl enable --now dhcpd
systemctl restart dhcpd
