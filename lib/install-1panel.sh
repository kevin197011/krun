#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::install::1panel::run() {
	# default platform
	platform='debian'
	# command -v apt >/dev/null && platform='debian'
	command -v yum >/dev/null && platform='centos'
	command -v brew >/dev/null && platform='mac'
	eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::1panel::centos() {
	yum install -y curl
	krun::install::1panel::common
}

# debian code
krun::install::1panel::debian() {
	apt install -y curl
	krun::install::1panel::common
}

# mac code
krun::install::1panel::mac() {
	echo "Don't install 1panel for mac."
	# krun::install::1panel::common
}

# common code
krun::install::1panel::common() {
	# https://github.com/1Panel-dev/1Panel
	curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh
	bash quick_start.sh
}

# run main
krun::install::1panel::run "$@"
