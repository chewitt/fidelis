#!/bin/bash
# SPDX-License-Identifier: (GPL-2.0+ OR MIT)

# ****** INSTRUCTIONS *******
#
# 1. Download with 'curl -OJ https://raw.githubusercontent.com/chewitt/fidelis/ubuntu.sh'
# 2. Make the script executable with 'chmod +x'
# 3. Run the main preparation with './ubuntu.sh prepare'
# 4. If the /dev/device for /opt/fidelis_endpoint is /dev/sdb, run './ubuntu.sh opt /dev/sdb'
# 5. Reboot the server
# 6. Install Fidelis Endpoint
#
# Tested with Ubuntu 22.04 LTS minimal server with only openssh-server preinstalled

test_root(){
  if [ "$(id -u)" != "0" ]; then
    echo "ERROR: This script must be run with sudo/root privileges"
    exit 1
  fi
}

test_ubuntu(){
  VERSION=$(grep -oP 'VERSION_ID="\K[\d.]+' /etc/os-release)
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
  echo "INFO: Preparation Completed. Please reboot before intalling Fidelis Endpoint!"
  echo ""
}

msg_opt_complete(){
  echo ""
  echo "INFO: Disk Preparation Completed!"
  echo ""
}

do_install(){
  # practical options for curl. use with care.
  CURL_OPTS="--insecure"

  # prevent needrestart during installs
  sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'l'"'"';/g' /etc/needrestart/needrestart.conf

  # prevent interactive installs
  DEBIAN_FRONTEND="noninteractive"
  apt-get -o Dpkg::Options::=--force-confold -o Dpkg::Options::=--force-confdef \
          -y --allow-downgrades --allow-remove-essential --allow-change-held-packages

  # update distro base image and remove old packages
  apt update
  apt-get -y dist-upgrade
  apt-get -y autoremove

  # install basic dependencies
  apt-get -y install apt-utils htop libdevmapper-dev lvm2 nano open-vm-tools p7zip-full screen sysstat

  # install packages needed for apt over https
  apt-get -y install apt-transport-https ca-certificates curl software-properties-common

  # install the docker GPG key
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

  # add the docker-ce repo to apt sources
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

  # ensure we use the docker repo not canonical
  apt-cache policy docker-ce

  # install required docker packages
  case ${VERSION} in
    22.04)
      apt-get -y install docker.io containerd
      ;;
  esac

  # restore needrestart config
  sed -i 's/$nrconf{restart} = '"'"'l'"'"';/#$nrconf{restart} = '"'"'i'"'"';/g' /etc/needrestart/needrestart.conf

  # enable and start docker services
  systemctl enable --now docker
  systemctl start docker

  # install docker compose
  DCVER=$(curl $CURL_OPTS --silent "https://api.github.com/repos/docker/compose/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  curl $CURL_OPTS -L "https://github.com/docker/compose/releases/download/$DCVER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose

  # ensure /usr/local/bin is in $PATH for future sessions
  echo 'export PATH=$PATH:/usr/local/bin' > /etc/profile.d/docker-compose.sh
}

do_tuning(){
  # set sysctl tuning
  tee /etc/sysctl.d/99-sysctl.conf > /dev/null <<EOF
fs.file-max=2097152
fs.nr_open=2097152
net.core.somaxconn=32768
net.ipv4.tcp_max_syn_backlog=16384
net.core.netdev_max_backlog=16384
net.ipv4.ip_local_port_range=1024 65535
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

  # set limits
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
  prepare)
    test_root
    test_ubuntu
    test_github
    do_install
    msg_install_complete
    ;;
  opt)
    do_opt "$@"
    msg_opt_complete
    ;;
  tuning)
    do_tuning
    ;;
  *)
    echo "ERROR: No options specified!"
    echo ""
    echo "examples:"
    echo "./ubuntu.sh prepare"
    echo "./ubuntu.sh tuning"
    echo "./ubuntu.sh opt /dev/sdb"
    echo ""
    ;;
esac

exit
