#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::install::awscli::run() {
	# default platform
	platform='debian'
	# command -v apt >/dev/null && platform='debian'
	command -v yum >/dev/null && platform='centos'
	command -v brew >/dev/null && platform='mac'
	eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::awscli::centos() {
	krun::install::awscli::common
}

# debian code
krun::install::awscli::debian() {
	krun::install::awscli::common
}

# mac code
krun::install::awscli::mac() {
	brew install awscli
	krun::install::awscli::common
}

# common code
krun::install::awscli::common() {
	echo 'common todo...'
}

# run main
krun::install::awscli::run "$@"
