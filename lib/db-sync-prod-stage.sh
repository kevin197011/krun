#!/usr/bin/env bash
# by kevin
#       _ _
#      | | |
#    __| | |__    ___ _   _ _ __   ___
#   / _` | '_ \  / __| | | | '_ \ / __|
#  | (_| | |_) | \__ \ |_| | | | | (__
#   \__,_|_.__/  |___/\__, |_| |_|\___|
#                      __/ |
#                     |___/
# Prod db sync to Stage script

# lock host
allow_host='10.10.0.110'

# prod vars
prod_db_host='10.20.0.110'
prod_db_user='root'
prod_db_pass='password'

# stage vars
stage_db_host='10.10.0.110'
stage_db_user='root'
stage_db_pass='password'


# start time
start_time=$(date +%s)


# only in allow_host can run!
host_ip=$(ifconfig eth0|grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}"|head -n 1)
[[ "${allow_host}" == "${host_ip}" ]] || echo "Not equal, exit!" ; exit -1


# backup prod database app
echo "backup prod database ..."
rm -rf /data/backup/app.sql.gz

mysqldump -h$prod_db_host -u$prod_db_user -p$prod_db_pass app | gzip > /data/backup/app.sql.gz


# drop stage database app
echo "drop stage database ..."
mysql -h$stage_db_host -u$stage_db_user -p$stage_db_pass -e "DROP DATABASE IF EXISTS app"


# create stage database app
echo "create stage database ..."
mysql -h$stage_db_host -u$stage_db_user -p$stage_db_pass -e "CREATE DATABASE app"


# import stage database app
echo "import stage database ..."
zcat /data/backup/app.sql.gz | mysql -h$stage_db_host -u$stage_db_user -p$stage_db_pass app


# end time
end_time=$(date +%s)


echo "Done!"
echo "Execute time: $(expr $end_time - $start_time)s"
