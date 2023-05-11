# Copyright (c) 2023 kk
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

(grep -w NAME /etc/os-release | grep -i centos) || echo "System unsupported, exit!"; exit 1

curl -sS https://webi.sh/k9s | sh

echo 'export PATH="/root/.local/bin:$PATH"' >> /etc/profile
echo 'source ~/.config/envman/PATH.env' >> /etc/profile


