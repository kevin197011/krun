#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::install::nginx::run() {
	# default platform
	platform='debian'
	# command -v apt >/dev/null && platform='debian'
	command -v yum >/dev/null && platform='centos'
	command -v brew >/dev/null && platform='mac'
	eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::nginx::centos() {
	krun::install::nginx::common
}

# debian code
krun::install::nginx::debian() {
	krun::install::nginx::common
}

# mac code
krun::install::nginx::mac() {
	krun::install::nginx::common
}

# common code
krun::install::nginx::common() {
	echo 'common todo...'
}

# run main
krun::install::nginx::run "$@"
