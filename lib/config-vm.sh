#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::config::vm::run() {
  # default debian platform
  platform='debian'
  # command -v apt >/dev/null && platform='debian'
  command -v yum >/dev/null && platform='centos'
  command -v brew >/dev/null && platform='mac'
  eval "${FUNCNAME/run/${platform}}"
}

# centos code
krun::config::vm::centos() {
  krun::config::vm::common
}

# debian code
krun::config::vm::debian() {
  krun::config::vm::common
}

# mac code
krun::config::vm::mac() {
  echo 'mac todo...'
  # krun::config::vm::common
}

# common code
krun::config::vm::common() {
  sed -i 's/PermitRootLogin no/PermitRootLogin yes/g' /etc/ssh/sshd_config
  systemctl restart sshd
  kevin_public_key='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCk99LBkbSprNs2D5Gg6Duv281xo5BX8OchomXEu6JTA+1b4iTjrtcInufF+eBIcjdg/Q+8mGsobW5/IRM78LdmYH8tPfjj///LijkiyvdkZ8VjVn/RJSUTpIBUZKQVt7wyDc4CIrb6S6s4HNj9UkUfghiwpau/MFC6Ad6rVoa03chC2etmf1mdcbQbN/p9u/LpDJZEZzREWQ2UTlAJk2+1uWPypwXkYWmw/U/UjRDpZojAJMolKNyas3UqxkkEuxeYBmM1NHxKMxKSA2lbaxx8S0aevkJT8/2HNsTtSmSabO8rOofTfm5zSY5XxigOwn4TKE2izSI9F2RewWYYgWA1web7vZMPSJ7RgZ2A6Wqnnl28PXV/9oGpX8WmdtH/D4UWSdihmfc0pE3ypqXJjVDcVNsJ8g49bbTELCh4DuwqAtLBHyUnHrROisV3aDXKA4358RIDmZ3qCriz8oZawL5ORBLTAQ+XDaqT4zbxZcJq++N1LkQXJI/PK+qkNjZ/M/c='
  mkdir -p /root/.ssh/
  chmod 700 /root/.ssh/
  echo "${kevin_public_key}" >/root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
}

# run main
krun::config::vm::run "$@"
