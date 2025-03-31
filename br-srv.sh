#!/bin/bash

# Set hostname and timezone

hostnamectl set-hostname br-srv.au-team.irpo
timedatectl set-timezone Asia/Yekaterinburg

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

