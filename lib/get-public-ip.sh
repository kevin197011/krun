# Copyright (c) 2022 kk
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

public_ip=$(curl -fsSL ifconfig.me)
echo ${public_ip}