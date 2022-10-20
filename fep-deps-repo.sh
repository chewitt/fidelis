#!/bin/bash

# Run on an internet connected RHEL compatible v8/v9 distro to create a local rpm repo
# with all dependencies for Fidelis Endpoint, or a tar file of the repo

# set the directory to store mirrored files in
MDIR="/opt/mirror"

# check priveliges
if [ "$(id -u)" != "0" ]; then
  echo "Error: This script must be run with sudo/root privileges" && exit 1
fi

# install dependencies for rpm creation
dnf install -y rpmdevtools rpmlint

create-mirror(){
  # check version
  VERSION=$(rpm --eval '%{centos_ver}')
  case ${VERSION} in
    5|6|7)
      echo "Error: RHEL/CentOS v${VERSION} is not supported" && exit 1
      ;;
    8|9)
      # supported RHEL/CentOS version, continue
      ;;
    *)
      echo "Error: Unknown OS version" && exit 1
      ;;
  esac

  # create directories
  mkdir -p "${MDIR}"

  # install the epel repo
  dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-${VERSION}.noarch.rpm

  # install the docker-ce repo
  dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

  # download packages and dependencies
  dnf update -y && dnf download -y \
      containerd.io \
      container-selinux \
      device-mapper-persistent-data \
      docker-ce \
      docker-ce-cli \
      htop \
      lvm2 \
      nano \
      open-vm-tools \
      p7zip \
      p7zip-plugins \
      screen \
      sysstat \
      yum-utils \
      --downloaddir ${MDIR} --resolve --alldeps

  # remove old rpm build tree
  rm -rf "~/rpmbuild"

  # create new rpm build tree
  rpmdev-setuptree

  # download docker-compose.spec
  curl -k "https://raw.githubusercontent.com/chewitt/fidelis/master/docker-compose.spec" -o "~/rpmbuild/SPECS/docker-compose.spec"

  # get the latest docker-compose version
  DCVER=$(curl -k -s "https://api.github.com/repos/docker/compose/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

  # set the version in the spec file
  sed -i "s/@@VERSION@@/${DCVER}/g" "~/rpmbuild/SPECS/docker-compose.spec"

  # get the docker-compose-linux-x86_64 source
  spectool -g -R SPECS/docker-compose.spec

  # build the rpm file
  rpmbuild -bb ~/rpmbuild/SPECS/docker-compose.spec

  # move the rpm file to the mirror
  DCRPM=$(find ~/rpmbuild -name docker-compose*.rpm)
  cp "${DCRPM}" "${MDIR}"

  # create the repo
  createrepo --update ${MDIR}
}

create-filerepo(){
  create-mirror
  tee /etc/yum.repos.d/fidelis-file.repo > /dev/null <<EOF
[fidelis-file]
name=Fidelis Endpoint Dependencies
baseurl=file://${MDIR}
enabled=1
gpgcheck=0
EOF
  dnf update
}

create-webrepo(){
  create-mirror
  dnf install -y nginx
  sed -i "s|/var/www/nginx/html|${MDIR}|g" /etc/nginx/nginx.conf
  systemctl restart nginx
  tee /etc/yum.repos.d/fidelis-nginx.repo > /dev/null <<EOF
[fidelis-nginx]
name=Fidelis Endpoint Dependencies
baseurl=http://localhost/
enabled=1
gpgcheck=0
EOF
  dnf update
}

create-tarfile(){
  create-mirror
  cd ${MDIR}
  mkdir -p "${MDIR}/tar"
  if [ ! -f /usr/bin/tar ]; then
    dnf install -y tar
  fi
  tar --exclude='iso' \
      --exclude='tar' \
      --exclude='index.html' \
      --exclude='fep-deps.repo' \
      -cvf "${MDIR}/tar/Fidelis-9.0-x86_64-deps.tar" *
}

show-help(){
  echo "sample usage: ./fep-deps-repo.sh <option>"
  echo ""
  echo "option: tar   (create a tarfile in ${MDIR}/tar)"
  echo "        file  (create a local repo and install .repo file)"
  echo "        web   (create a local repo and install nginx)"
  echo "        help  (show these options)"
  echo ""
}

case $1 in
  tar)
    create-tarfile
    ;;
  file)
    create-filerepo
    ;;
  web)
    create-webrepo
    ;;
  *|help)
    show-help
    ;;
esac

exit
