# Copyright (c) 2023 kk
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

yum install perl-Digest-MD5 -y
yum install https://repo.percona.com/yum/percona-release-latest.noarch.rpm -y
percona-release enable-only tools release
yum install -y https://www.percona.com/downloads/XtraBackup/Percona-XtraBackup-2.4.4/\
              binary/redhat/7/x86_64/percona-xtrabackup-24-2.4.4-1.el7.x86_64.rpm
yum install lz4 -y