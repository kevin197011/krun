#!/usr/bin/env bash

# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# install kssh to mac

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-kssh.sh | bash

# vars

# run code
krun::install::kssh::run() {
    krun::install::kssh::mac
}

# mac code
krun::install::kssh::mac() {
    git clone https://github.com/kevin197011/kssh.git ~/.kssh
    cd .kssh && bundle install
    grep -q 'export PATH="$PATH:~/.kssh/bin"' ~/.zshrc || echo 'export PATH="$PATH:~/.kssh/bin"' >>~/.zshrc
    zsh
}

# run main
krun::install::kssh::run "$@"
