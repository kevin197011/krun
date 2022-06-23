# Copyright (c) 2022 Operator
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

yum install -y epel-release
yum install -y bash-completion bash-completion-extras
timedatectl set-timezone Asia/Hong_Kong
yum upgrade -y
yum update -y

yum install -y ncdu

yum-config-manager --add-repo=https://copr.fedorainfracloud.org/coprs/carlwgeorge/ripgrep/repo/epel-7/carlwgeorge-ripgrep-epel-7.repo
yum install -y ripgrep

yum install lrzsz -y