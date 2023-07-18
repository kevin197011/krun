#!/usr/bin/env bash
# by Kk
# Prod db sync to Stage script

echo -e " \
________________     _________  ______   __________
___  __ \__  __ )    __  ___/ \/ /__  | / /_  ____/
__  / / /_  __  |    _____ \__  /__   |/ /_  /
_  /_/ /_  /_/ /     ____/ /_  / _  /|  / / /___
/_____/ /_____/      /____/ /_/  /_/ |_/  \____/


Powered by Kk
"

# prepare working directory
workdir='/data/backup'

mkdir -p ${workdir}

# need sync databases
databases=(
  database1
  database2
)

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

# backup prod database
echo "backup prod database ..."
rm -rf /data/backup/*.sql.gz

for db in "${databases[@]}"; do
  echo "prod backup $db ..."
  mysqldump -h$prod_db_host -u$prod_db_user -p$prod_db_pass $db | gzip >/data/backup/$db.sql.gz
  echo "prod backup $db done."
done

# drop stage database
for db in "${databases[@]}"; do
  echo "stage drop $db ..."
  mysql -h$stage_db_host -u$stage_db_user -p$stage_db_pass -e "DROP DATABASE IF EXISTS $db"
  echo "stage drop $db done."
done

# create stage database
for db in "${databases[@]}"; do
  echo "stage create $db ..."
  mysql -h$stage_db_host -u$stage_db_user -p$stage_db_pass -e "CREATE DATABASE $db"
  echo "stage create $db done."
done

# import stage database app
for db in "${databases[@]}"; do
  echo "stage import $db ..."
  zcat /data/backup/$db.sql.gz | mysql -h$stage_db_host -u$stage_db_user -p$stage_db_pass $db
  echo "stage import $db done."
done

# end time
end_time=$(date +%s)

echo "Sync Done!"
echo "Execute time: $(expr $end_time - $start_time)s"
