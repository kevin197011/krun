# Copyright (c) 2022 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# VirtualBox
yum install -y epel-release && \
yum install -y gcc dkms make qt libgomp patch && \
yum install -y kernel-headers kernel-devel binutils glibc-headers glibc-devel fontforge && \
wget http://download.virtualbox.org/virtualbox/rpm/rhel/virtualbox.repo -O /etc/yum.repos.d/virtualbox.repo && \
yum install -y VirtualBox-5.2

# vagrant
yum install -y https://releases.hashicorp.com/vagrant/2.2.19/vagrant_2.2.19_x86_64.rpm && \
vagrant --version

# images
vagrant box add centos/7
vagrant box add ubuntu/trusty64

# create vms
# mkdir -p /tmp/node01 && cd /tmp/node01 && \
# vagrant init centos/7 && vagrant up
# vagrant ssh