#!/bin/bash

# Set hostname and timezone

hostnamectl set-hostname hq-srv.au-team.irpo
timedatectl set-timezone Asia/Yekateringburg

# Configuring dns-server

apt-get install -y dnsmasq

systemctl enable --now dnsmasq

cat <<EOF >> /etc/dnsmasq.conf
server=8.8.8.8
domain=au-team.irpo
local=/au-team.irpo/
address=/hq-rtr.au-team.irpo/172.16.4.1
address=/br-rtr.au-team.irpo/172.16.5.1
address=/hq-srv.au-team.irpo/192.168.100.2
address=/hq-cli.au-team.irpo/192.168.200.3 
address=/br-srv.au-team.irpo/192.168.3.2
cname=hq-rtr.au-team.irpo,moodle.au-team.irpo,wiki.au-team.irpo
ptr-record=1.4.16.172.in-addr.arpa,"hq-rtr.au-team.irpo"
ptr-record=2.100.168.192.in-addr.arpa,"hq-srv.au-team.irpo"
ptr-record=3.200.168.192.in-addr.arpa,"hq-cli.au-team.irpo"
interface=ens18.100
EOF

systemctl restart dnsmasq

# Adding user 
# After script is executed you should write: passwd sshuser

useradd -d /home/sshuser -u 1010 sshuser
usermod -aG wheel sshuser
echo "WHEEL_USERS ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers

# Banner

cat <<EOF > /etc/issue.net
##########################
# Authorized access only #
##########################
EOF

