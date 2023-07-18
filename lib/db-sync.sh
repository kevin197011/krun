#!/usr/bin/env bash
# by Kk
# mysql or mariadb db sync script

echo -e " \
________________     _________  ______   __________
___  __ \__  __ )    __  ___/ \/ /__  | / /_  ____/
__  / / /_  __  |    _____ \__  /__   |/ /_  /
_  /_/ /_  /_/ /     ____/ /_  / _  /|  / / /___
/_____/ /_____/      /____/ /_/  /_/ |_/  \____/


Powered by Kk
"

# import .env
# cat ~/.env
# # prod vars
# source_db_host='10.20.0.110'
# source_db_user='root'
# source_db_pass='password'

# # stage vars
# destination_db_host='10.10.0.110'
# destination_db_user='root'
# destination_db_pass='password'
source ~/.env >/dev/null 2>&1 || {
  echo "~/.env not found, exit!"
  exit 1
}
# prepare working directory
workdir='/data/backup'

mkdir -p ${workdir}

# need sync databases
databases=(
  database1
  database2
)

# start time
start_time=$(date +%s)

# backup prod database
echo "backup prod database ..."
rm -rf /data/backup/*.sql.gz

for db in "${databases[@]}"; do
  echo "prod backup $db ..."
  mysqldump -h$source_db_host -u$source_db_user -p$source_db_pass $db | gzip >/data/backup/$db.sql.gz
  echo "prod backup $db done."
done

# drop stage database
for db in "${databases[@]}"; do
  echo "stage drop $db ..."
  mysql -h$destination_db_host -u$destination_db_user -p$destination_db_pass -e "DROP DATABASE IF EXISTS $db"
  echo "stage drop $db done."
done

# create stage database
for db in "${databases[@]}"; do
  echo "stage create $db ..."
  mysql -h$destination_db_host -u$destination_db_user -p$destination_db_pass -e "CREATE DATABASE $db"
  echo "stage create $db done."
done

# import stage database app
for db in "${databases[@]}"; do
  echo "stage import $db ..."
  zcat /data/backup/$db.sql.gz | mysql -h$destination_db_host -u$destination_db_user -p$destination_db_pass $db
  echo "stage import $db done."
done

# end time
end_time=$(date +%s)

echo "Sync Done!"
echo "Execute time: $(expr $end_time - $start_time)s"
