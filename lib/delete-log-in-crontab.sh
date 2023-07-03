# Copyright (c) 2023 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

mkdir -p /opt/scripts

scritp_name='delete-log.sh'

tee /opt/scripts/${scritp_name} >/dev/null <<EOF
#!/usr/bin/env sh
# Copyright (c) 2023 Operator
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
for d in \${dirs[@]}; do
    find \${d} -name "*.log*" -type f -mtime +\${days} -delete
    # find \${d} -name "*.out*" -type f -mtime +\${days} -delete
done
EOF

echo "add /opt/scripts/${scritp_name} ok!"

tee /etc/cron.daily/${scritp_name} >/dev/null <<EOF
#!/usr/bin/env sh
# Copyright (c) 2023 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

bash /opt/scripts/${scritp_name}
EOF

echo "add /etc/cron.daily/${scritp_name} ok!"

chmod +x /opt/scripts/${scritp_name}
chmod +x /etc/cron.daily/${scritp_name}

echo "chmod /opt/scripts/${scritp_name} ok!"
echo "chmod /etc/cron.daily/${scritp_name} ok!"

# delete
# rm -rf /opt/scripts/${scritp_name}
# rm -rf /etc/cron.daily/${scritp_name}
