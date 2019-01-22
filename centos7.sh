#!/bin/bash

# this script must be run as root
if [ "$(id -u)" != "0" ]; then
  echo ""
  echo "FAIL: This script must be run with sudo/root privileges"
  echo ""
fi

# install basic packages
yum install -y yum-utils device-mapper-persistent-data lvm2

# install docker-ce and EPEL repos
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y epel-release

# update base OS
yum update -y

# install required packages
yum install -y docker-ce docker-ce-cli containerd.io p7zip p7zip-plugins

# start docker services
systemctl start docker

# install docker compose
DCVER=$(curl --silent "https://api.github.com/repos/docker/compose/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
curl -L "https://github.com/docker/compose/releases/download/$DCVER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# configure firewall for fidelis services
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=444/tcp
firewall-cmd --permanent --add-port=445/tcp
firewall-cmd --permanent --add-port=5432/tcp
firewall-cmd --permanent --add-port=8440/tcp
firewall-cmd --permanent --add-port=8887/tcp
firewall-cmd --permanent --add-port=8888/tcp
firewall-cmd --permanent --add-port=8889/tcp
firewall-cmd --permanent --add-port=9001/tcp
firewall-cmd --permanent --add-port=9200/tcp
firewall-cmd --permanent --add-port=9300/tcp
firewall-cmd --permanent --add-port=9333/tcp
firewall-cmd --reload

# set sysctl tuning
tee /etc/sysctl.d/99-sysctl.conf > /dev/null <<EOF
fs.file-max=2097152
fs.nr_open=2097152
net.core.somaxconn=32768
net.ipv4.tcp_max_syn_backlog=16384
net.core.netdev_max_backlog=16384
net.ipv4.ip_local_port_range=1000 65535
net.core.rmem_default=262144
net.core.wmem_default=262144
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.core.optmem_max=16777216
net.ipv4.tcp_rmem=1024 4096 16777216
net.ipv4.tcp_wmem=1024 4096 16777216
net.nf_conntrack_max=1000000
net.netfilter.nf_conntrack_max=1000000
net.netfilter.nf_conntrack_tcp_timeout_time_wait=30
net.ipv4.tcp_max_tw_buckets=1048576
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_fin_timeout=15
net.ipv4.neigh.default.gc_thresh1=0
net.ipv4.neigh.default.gc_thresh2=16384
net.ipv4.neigh.default.gc_thresh3=32768
vm.max_map_count=655300
EOF

tee /etc/security/limits.d/21-nofile.conf > /dev/null <<EOF
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF

# reload sysctl
sysctl -p

echo "CONFIG COMPLETED"
exit 0
