#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# run code
krun::install::openjdk8::run() {
	# default platform
	platform='debian'
	# command -v apt >/dev/null && platform='debian'
	command -v yum >/dev/null && platform='centos'
	command -v brew >/dev/null && platform='mac'
	eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::openjdk8::centos() {
	yum install -y java-1.8.0-openjdk
	krun::install::openjdk8::common
}

# debian code
krun::install::openjdk8::debian() {
	apt update
	apt install openjdk-8-jdk
	krun::install::openjdk8::common
}

# mac code
krun::install::openjdk8::mac() {
	asdf plugin-add java
	asdf list-all java
	# asdf install java openjdk-8 not available
	asdf install java openjdk-20
	asdf global java openjdk-20
	krun::install::openjdk8::common
}

# common code
krun::install::openjdk8::common() {
	java --version
}

# run main
krun::install::openjdk8::run "$@"
