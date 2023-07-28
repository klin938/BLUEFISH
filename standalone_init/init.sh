#!/bin/bash

cp -f *_dev /root/

cp -f epel.repo /etc/yum.repos.d/epel.repo
cp -f RPM-GPG-KEY-EPEL-7 /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

yum clean all

# no network at this point, install after reboot
#yum install -y git vim ansible --enablerepo=epel

#
# account
#
groupadd -g xxxx dummy
useradd --no-create-home -d /export/apps/dummy -u 1008 -g dummy dummy

echo "%mugiwara ALL=(ALL) ALL" > /etc/sudoers.d/dummy

#
# networking
#
systemctl stop NetworkManager
systemctl disable NetworkManager
systemctl is-enabled NetworkManager

cp -f ifcfg-em2 /etc/sysconfig/network-scripts/ifcfg-em2
cp -f route-em2 /etc/sysconfig/network-scripts/route-em2
rm -f /etc/resolv.conf
cp -f resolv.conf /etc/resolv.conf

printf "\n**init setup completed** Please:\n\n      1) set a new password for luffy -> reboot\n\n      2) yum groupinstall -y \"Development tools\" -> install mlnx_ofed driver manually -> reboot\n\n      3) install ansible, git, vim -> run BLUEFISH\n"
