#!/bin/bash
# SPDX-License-Identifier: (GPL-2.0+ OR MIT)

test_root(){
  if [ "$(id -u)" != "0" ]; then
    echo "ERROR: This script must be run with sudo/root privileges"
    exit 1
  fi
}

test_github(){
  CURL=$(curl -k -sI https://github.com | head -n 1 | grep 200)
  if [ -z "$CURL" ]; then
    echo "ERROR: Unable to contact GitHub!"
    echo ""
    echo "If a proxy is required use: export http_proxy=http://proxy:3128"
    exit 1
  fi
}

msg_install_complete(){
  echo ""
  echo "INFO: CentOS7 Preparation Completed. Please reboot before intalling Fidelis Endpoint!"
  echo ""
}

msg_opt_complete(){
  echo ""
  echo "INFO: CentOS7 Disk Preparation Completed!"
  echo ""
}

do_install(){

  # practical options for curl. use with care.
  CURL_OPTS="--insecure"
  # install basic packages
  yum install -y yum-utils device-mapper-persistent-data lvm2

  # install docker-ce
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  # install EPEL using rpm so it works for both RHEL and CentOS
  yum install -y http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

  # update base OS
  yum update -y

  # install required packages
  yum install -y http://mirror.centos.org/centos/7/extras/x86_64/Packages/container-selinux-2.107-3.el7.noarch.rpm
  yum install -y docker-ce docker-ce-cli containerd.io p7zip p7zip-plugins

  # start docker services
  systemctl start docker
  # enable docker on boot
  systemctl enable docker

  # install docker compose
  DCVER=$(curl $CURL_OPTS --silent "https://api.github.com/repos/docker/compose/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  curl $CURL_OPTS -L "https://github.com/docker/compose/releases/download/$DCVER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose

  # ensure /usr/local/bin is in $PATH for future sessions
  echo 'pathmunge /usr/local/bin' > /etc/profile.d/docker-compose.sh

  # configure firewall for fidelis services if firewallD is running

  firewall-cmd --state &>/dev/null
  if [ $? -eq 0 ]; 
    then 
      echo "Firewall is running, adding exceptions."
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
    else
      echo "Firewall is not running." 
  fi

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
}

do_opt(){
  if [ -z "$2" ]; then
    echo "ERROR: No /dev/device specified!"
    exit 1
  else
    pvcreate "$2"
    vgcreate fidelis "$2"
    lvcreate -l 100%VG -n opt fidelis "$2"
    mkfs.ext4 -F /dev/mapper/fidelis-opt
    mkdir -p /opt/fidelis_endpoint
    echo "/dev/mapper/fidelis-opt /opt/fidelis_endpoint ext4 defaults 0 0" >> /etc/fstab
    mount /opt/fidelis_endpoint
  fi
}

case $1 in
  install)
    test_root
    test_github
    do_install
    msg_install_complete
    ;;
  opt)
    do_opt "$@"
    msg_opt_complete
    ;;
  *)
    echo "ERROR: No options specified!"
    echo ""
    echo "examples:"
    echo "./centos7.sh install"
    echo "./centos7.sh opt /dev/sdb"
    echo ""
    ;;
esac

exit
