cdrom
keyboard gb
lang en_GB.UTF-8
timezone UTC
network --bootproto=dhcp --noipv6 --onboot=on --hostname=fidelis
firewall --enabled --service ssh
selinux --permissive
skipx
zerombr
clearpart --all --initlabel
autopart --nohome --nolvm --noboot --fstype=ext4
bootloader --timeout=1 --location=mbr
firstboot --disabled
reboot --eject
rootpw --plaintext Fidelis123$
user --name=fidelis --plaintext --password Fidelis123$
repo --name="minimal" --baseurl=file:///run/install/sources/mount-0000-cdrom/minimal
repo --name="fidelis" --baseurl=file:///run/install/repo/fidelis

%packages --ignoremissing --excludedocs --inst-langs=en_GB.utf8
# minimal packages
openssh-clients
sudo
tar
dnf-utils
# fidelis packages
containerd.io
container-selinux
device-mapper-persistent-data
docker-ce
docker-ce-cli
docker-compose
lvm2
p7zip
p7zip-plugins
sysstat
htop
nano
open-vm-tools
screen
# exclusions
-fprintd-pam
-intltool
-iwl*-firmware
-microcode_ctl
%end

%post
# add fidelis user to sudoers
usermod -aG wheel fidelis

# force password change on login
passwd --expire fidelis
passwd --expire root

# enable docker
systemctl enable docker

%end
