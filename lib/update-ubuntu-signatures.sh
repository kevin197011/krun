# Copyright (c) 2022 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT


# repositories_release_key="$1"

# wget -qO - ${repositories_release_key} | apt-key --keyring /etc/apt/trusted.gpg add -
wget -qO - http://download.opensuse.org/repositories/home:/Provessor/xUbuntu_20.04/Release.key | apt-key --keyring /etc/apt/trusted.gpg add -