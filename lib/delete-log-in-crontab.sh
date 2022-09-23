# Copyright (c) 2022 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

mkdir -p /opt/scripts

scritp_name='delete-log.sh'

tee /opt/scripts/${scritp_name} <<EOF
#!/usr/bin/env sh
# Copyright (c) 2022 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# days
days=7

# log path
dirs=(
    "/data/logs"
) 

# delete old logs
for d in ${dirs[@]}; do
    find ${d} -name "*.log" -type f -mtime +${days} -delete
done
EOF

tee /etc/cron.daily/${scritp_name} <<EOF
#!/usr/bin/env sh
# Copyright (c) 2022 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

bash /opt/scripts/${scritp_name}
EOF

chmod +x /opt/scripts/${scritp_name}
chmod +x /etc/cron.daily/${scritp_name}


# delete
# rm -rf /opt/scripts/${scritp_name}
# rm -rf /etc/cron.daily/${scritp_name}