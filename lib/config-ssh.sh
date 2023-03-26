# Copyright (c) 2022 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT


perl -i -pe 's/(\s*)(#*)(\s*)PasswordAuthentication(.*)/PasswordAuthentication no/g' /etc/ssh/sshd_config
perl -i -pe 's/(\s*)(#*)(\s*)PermitRootLogin(.*)/PermitRootLogin no/g' /etc/ssh/sshd_config
systemctl restart sshd