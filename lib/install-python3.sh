# Copyright (c) 2022 kk
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

if [[ -f /usr/bin/apt ]]; then
    apt install software-properties-common -y
    add-apt-repository ppa:deadsnakes/ppa
    apt update
fi