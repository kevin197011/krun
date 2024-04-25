#!/usr/bin/env bash
# Copyright (c) 2024 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# vars

# run code
krun::install::oh_my_zsh::run() {
    # default platform
    platform='debian'
    # command -v apt >/dev/null && platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::oh_my_zsh::centos() {
    krun::install::oh_my_zsh::common
}

# debian code
krun::install::oh_my_zsh::debian() {
    krun::install::oh_my_zsh::common
}

# mac code
krun::install::oh_my_zsh::mac() {
    krun::install::oh_my_zsh::common
}

# common code
krun::install::oh_my_zsh::common() {
    curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | bash
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/agkozak/zsh-z $ZSH_CUSTOM/plugins/zsh-z
    krun install-nerd-fonts.sh
}

# run main
krun::install::oh_my_zsh::run "$@"
