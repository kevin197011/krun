# Copyright (c) 2023 kk
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# mysql
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022 
yum localinstall https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm  -y
yum install mysql-community-server -y

# data
mkdir -pv /data/mysql
mkdir -pv /data/logs/mysql
chown -R mysql:mysql /data/