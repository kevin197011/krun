# Copyright (c) 2022 kk
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# permit root login in
perl -i.bak -pe 's/^(\s*)PasswordAuthentication(\s*)no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd
echo "123456" | passwd "root" --stdin
