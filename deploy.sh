# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

export deploy_path=${deploy_path:-"$HOME/.krun"}

deploy::install() {
    mkdir -pv "${deploy_path}"/bin
    mkdir -pv "${deploy_path}"/config
    curl -s -o "${deploy_path}"/bin/krun https://raw.githubusercontent.com/kevin197011/krun/main/bin/krun
    chmod +x "${deploy_path}"/bin/krun
}

deploy::config() {
    # mac
    command -v brew >/dev/null && (grep -q "${deploy_path}/bin" ~/.zshrc || echo "export PATH=\$PATH:${deploy_path}/bin" >>~/.zshrc)
    # ubuntu
    [[ -f /etc/lsb-release ]] && grep -qi "ubuntu" /etc/lsb-release &&
        apt-get update && apt-get install python3 -y && ln -sf /usr/bin/python3 /usr/bin/python
    grep -q "${deploy_path}/bin" ~/.bashrc || echo "export PATH=\$PATH:${deploy_path}/bin" >>~/.bashrc
}

deploy::status() {
    command -v brew >/dev/null && /bin/zsh || source /bin/bash
    krun status
}

deploy::uninstall() {
    rm -rf "${deploy_path}"
}

deploy::main() {
    deploy::install
    deploy::config
    deploy::status
}

# run main
deploy::main "$@"
