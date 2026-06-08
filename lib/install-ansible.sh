#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-ansible.sh | bash
#
# Official docs:
# - https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html
# - https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html

# vars
# ansible: full package with collections; ansible-core: minimal runtime
ansible_package=${ansible_package:-ansible}
# auto | pkg | pip | pipx
ansible_install_method=${ansible_install_method:-auto}
ansible_install_argcomplete=${ansible_install_argcomplete:-false}

# run code
krun::install::ansible::run() {
    local platform='debian'
    command -v dnf >/dev/null && platform='centos'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::ansible::centos() {
    echo "Installing Ansible on CentOS/RHEL/Fedora..."
    [[ "$(id -u)" -ne 0 ]] && echo "✗ Please run as root for package installation" && return 1

    if command -v dnf >/dev/null 2>&1; then
        dnf install -y python3 python3-pip curl
    else
        yum install -y python3 python3-pip curl
    fi

    krun::install::ansible::common
}

# debian code
krun::install::ansible::debian() {
    echo "Installing Ansible on Debian/Ubuntu..."
    [[ "$(id -u)" -ne 0 ]] && echo "✗ Please run as root for package installation" && return 1

    apt-get update
    apt-get install -y python3 python3-pip curl ca-certificates gnupg wget software-properties-common

    krun::install::ansible::common
}

# mac code
krun::install::ansible::mac() {
    echo "Installing Ansible on macOS..."

    if command -v ansible >/dev/null 2>&1; then
        echo "✓ Ansible already installed"
        krun::install::ansible::verify_installation
        return 0
    fi

    if [[ "$ansible_install_method" == "auto" || "$ansible_install_method" == "pkg" ]]; then
        if command -v brew >/dev/null 2>&1; then
            if brew install ansible; then
                krun::install::ansible::verify_installation
                return 0
            fi
            echo "Homebrew install failed, falling back to pip..." >&2
        fi
    fi

    krun::install::ansible::install_with_pip
    krun::install::ansible::verify_installation
}

krun::install::ansible::common() {
    if command -v ansible >/dev/null 2>&1; then
        echo "✓ Ansible already installed"
        krun::install::ansible::verify_installation
        return 0
    fi

    case "$ansible_install_method" in
        pip)
            krun::install::ansible::install_with_pip
            ;;
        pipx)
            krun::install::ansible::install_with_pipx
            ;;
        pkg)
            krun::install::ansible::install_with_pkg || krun::install::ansible::install_with_pip
            ;;
        auto)
            if krun::install::ansible::install_with_pkg; then
                :
            else
                echo "Package install unavailable, falling back to pip..." >&2
                krun::install::ansible::install_with_pip
            fi
            ;;
        *)
            echo "✗ Unknown ansible_install_method: ${ansible_install_method}" >&2
            return 1
            ;;
    esac

    krun::install::ansible::verify_installation
}

krun::install::ansible::is_fedora_family() {
    [[ -f /etc/fedora-release ]] && return 0
    [[ -f /etc/os-release ]] || return 1

    local id
    id=$(. /etc/os-release && echo "$ID")
    case "$id" in
        fedora | centos | rhel | rocky | almalinux | ol | amzn) return 0 ;;
        *) return 1 ;;
    esac
}

krun::install::ansible::enable_epel() {
    krun::install::ansible::is_fedora_family || return 0
    [[ -f /etc/fedora-release ]] && return 0

    if command -v dnf >/dev/null 2>&1; then
        dnf install -y epel-release || true
    else
        yum install -y epel-release || true
    fi
}

krun::install::ansible::install_with_pkg() {
    if [[ -f /etc/debian_version ]]; then
        krun::install::ansible::install_debian_pkg
        return $?
    fi

    if krun::install::ansible::is_fedora_family; then
        krun::install::ansible::install_fedora_family_pkg
        return $?
    fi

    return 1
}

krun::install::ansible::install_fedora_family_pkg() {
    local pkg="$ansible_package"

    echo "Installing ${pkg} from distribution repositories (dnf/yum)..."
    krun::install::ansible::enable_epel

    if command -v dnf >/dev/null 2>&1; then
        dnf install -y "$pkg"
    else
        yum install -y "$pkg"
    fi
}

krun::install::ansible::debian_ubuntu_codename() {
    . /etc/os-release

    if [[ "$ID" == "ubuntu" ]]; then
        echo "$VERSION_CODENAME"
        return 0
    fi

    case "${VERSION_ID:-}" in
        13 | 13.*) echo "noble" ;;
        12 | 12.*) echo "jammy" ;;
        11 | 11.*) echo "focal" ;;
        *) echo "jammy" ;;
    esac
}

krun::install::ansible::install_debian_pkg() {
    . /etc/os-release

    echo "Installing ${ansible_package} from Ansible PPA/repositories..."

    if [[ "$ID" == "ubuntu" ]]; then
        add-apt-repository --yes --update ppa:ansible/ansible
        DEBIAN_FRONTEND=noninteractive apt-get install -y "$ansible_package"
        return 0
    fi

    local ubuntu_codename keyring="/usr/share/keyrings/ansible-archive-keyring.gpg"
    ubuntu_codename=$(krun::install::ansible::debian_ubuntu_codename)

    install -d -m 0755 /usr/share/keyrings
    wget -qO- "https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367" |
        gpg --dearmor -o "$keyring"
    echo "deb [signed-by=${keyring}] http://ppa.launchpad.net/ansible/ansible/ubuntu ${ubuntu_codename} main" |
        tee /etc/apt/sources.list.d/ansible.list >/dev/null

    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y "$ansible_package"
}

krun::install::ansible::ensure_pip() {
    local python_bin="${1:-python3}"

    if "$python_bin" -m pip -V >/dev/null 2>&1; then
        return 0
    fi

    echo "pip not found for ${python_bin}, installing python3-pip..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get install -y python3-pip
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y python3-pip
    elif command -v yum >/dev/null 2>&1; then
        yum install -y python3-pip
    else
        curl -fsSL https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
        "$python_bin" /tmp/get-pip.py --user
        rm -f /tmp/get-pip.py
    fi
}

krun::install::ansible::install_with_pip() {
    local python_bin="python3"
    local pip_args=(--user)

    command -v python3 >/dev/null 2>&1 || python_bin="python"
    krun::install::ansible::ensure_pip "$python_bin"

    echo "Installing ${ansible_package} with pip (${python_bin} -m pip install --user)..."
    "$python_bin" -m pip install "${pip_args[@]}" "$ansible_package"

    krun::install::ansible::install_argcomplete pip "$python_bin"
}

krun::install::ansible::install_with_pipx() {
    if ! command -v pipx >/dev/null 2>&1; then
        echo "pipx not found, installing via pip..."
        python3 -m pip install --user pipx
        python3 -m pipx ensurepath || true
    fi

    echo "Installing ${ansible_package} with pipx..."
    if [[ "$ansible_package" == "ansible" ]]; then
        pipx install --include-deps ansible
    else
        pipx install ansible-core
    fi

    krun::install::ansible::install_argcomplete pipx
}

krun::install::ansible::install_argcomplete() {
    [[ "$ansible_install_argcomplete" == "true" ]] || return 0

    local mode="${1:-pip}"
    local python_bin="${2:-python3}"

    echo "Installing argcomplete for shell completion..."
    case "$mode" in
        pipx)
            pipx inject --include-apps ansible argcomplete || true
            ;;
        *)
            "$python_bin" -m pip install --user argcomplete || true
            ;;
    esac
}

krun::install::ansible::ensure_user_local_bin_in_path() {
    local user_bin="${HOME}/.local/bin"
    [[ -d "$user_bin" ]] || return 0
    [[ ":$PATH:" == *":${user_bin}:"* ]] && return 0

    export PATH="${user_bin}:${PATH}"
    echo "⚠ Added ${user_bin} to PATH for this session"
    echo "  Add to your shell profile: export PATH=\"${user_bin}:\$PATH\""
}

krun::install::ansible::verify_installation() {
    echo "Verifying Ansible installation..."
    krun::install::ansible::ensure_user_local_bin_in_path

    if command -v ansible >/dev/null 2>&1; then
        echo "✓ ansible command is available"
        ansible --version
    else
        echo "✗ ansible command not found"
        return 1
    fi

    if command -v ansible-community >/dev/null 2>&1; then
        echo "✓ ansible-community command is available"
        ansible-community --version
    fi

    echo ""
    echo "Common commands:"
    echo "  ansible --version"
    echo "  ansible all -m ping -i 'host,'"
    echo "  ansible-galaxy collection install community.general"
    echo ""
    echo "Ansible is ready to use!"
}

# run main
krun::install::ansible::run "$@"
