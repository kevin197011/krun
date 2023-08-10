# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# very useful
source tests/.env

ssh -Tq ${t_ip} <<EOF
source /etc/profile
sudo touch /opt/tt.txt1
ls /opt -lh
echo "${t_ip}"
exit
EOF
