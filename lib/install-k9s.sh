#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::install::k9s::run() {
	# default platform
	platform='debian'
	# command -v apt >/dev/null && platform='debian'
	command -v yum >/dev/null && platform='centos'
	command -v brew >/dev/null && platform='mac'
	eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::k9s::centos() {
	krun::install::k9s::common
}

# debian code
krun::install::k9s::debian() {
	krun::install::k9s::common
}

# mac code
krun::install::k9s::mac() {
	# krun::install::k9s::common
	brew install k9s
}

# common code
krun::install::k9s::common() {
	curl -sS https://webi.sh/k9s | sh
	echo 'export PATH="/root/.local/bin:$PATH"' >>/root/.bashrc
	echo 'source ~/.config/envman/PATH.env' >>/root/.bashrc
	bash
}

# run main
krun::install::k9s::run "$@"
