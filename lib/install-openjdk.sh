#!/usr/bin/env bash
# Copyright (c) 2023 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-openjdk.sh | bash

# vars
java_version=${java_version:-17}

# run code
krun::install::openjdk::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::openjdk::centos() {
    echo "Installing OpenJDK ${java_version} on CentOS/RHEL..."
    yum install -y java-${java_version}-openjdk java-${java_version}-openjdk-devel || {
        echo "Package manager installation failed, trying alternative method..."
        krun::install::openjdk::manual_install
        return
    }
    krun::install::openjdk::common
}

# debian code
krun::install::openjdk::debian() {
    echo "Installing OpenJDK ${java_version} on Debian/Ubuntu..."
    apt-get update && apt-get install -y openjdk-${java_version}-jdk openjdk-${java_version}-jre || {
        echo "Package manager installation failed, trying alternative method..."
        krun::install::openjdk::manual_install
        return
    }
    krun::install::openjdk::common
}

# mac code
krun::install::openjdk::mac() {
    echo "Installing OpenJDK ${java_version} on macOS..."

    command -v java >/dev/null && echo "✓ Java already installed" && krun::install::openjdk::common && return

    if command -v brew >/dev/null; then
        case $java_version in
        8) brew install --cask adoptopenjdk8 ;;
        11) brew install openjdk@11 ;;
        17) brew install openjdk@17 ;;
        21) brew install openjdk@21 ;;
        *) brew install openjdk ;;
        esac
        echo "✓ OpenJDK ${java_version} installed via Homebrew"
        krun::install::openjdk::common
        return
    fi

    echo "Homebrew not found, trying manual installation..."
    krun::install::openjdk::manual_install
}

# common code
krun::install::openjdk::common() {
    command -v java >/dev/null && echo "✓ Java installed: $(java -version 2>&1 | head -1)" || {
        echo "✗ Java not found"
        return 1
    }

    krun::install::openjdk::configure_java_home
    command -v javac >/dev/null && echo "✓ Java compiler available" || echo "⚠ Java compiler not found"
}

# Configure JAVA_HOME environment variable
krun::install::openjdk::configure_java_home() {
    local java_home=""

    # Find JAVA_HOME
    if [[ "$(uname)" == "Darwin" ]]; then
        command -v /usr/libexec/java_home >/dev/null && java_home=$(/usr/libexec/java_home 2>/dev/null)
    else
        local java_path=$(readlink -f $(which java) 2>/dev/null)
        [[ -n "$java_path" ]] && java_home="${java_path%/bin/java}"
        [[ "$java_home" =~ jre$ ]] && java_home="${java_home%/jre}"

        # Common locations
        [[ -z "$java_home" || ! -d "$java_home" ]] && {
            local homes=("/usr/lib/jvm/java-${java_version}-openjdk" "/usr/lib/jvm/default-java")
            for home in "${homes[@]}"; do
                [[ -d "$home" ]] && java_home="$home" && break
            done
        }
    fi

    [[ -n "$java_home" && -d "$java_home" ]] && {
        export JAVA_HOME="$java_home"
        echo "✓ JAVA_HOME: $java_home"

        # Add to shell profiles
        local profiles=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")
        for profile in "${profiles[@]}"; do
            [[ -f "$profile" ]] && ! grep -q "JAVA_HOME" "$profile" 2>/dev/null && {
                echo "" >>"$profile"
                echo "export JAVA_HOME=\"$java_home\"" >>"$profile"
                echo "export PATH=\"\$JAVA_HOME/bin:\$PATH\"" >>"$profile"
            }
        done
    } || echo "⚠ JAVA_HOME not configured"
}

# manual installation
krun::install::openjdk::manual_install() {
    echo "Manual installation not implemented for OpenJDK"
    echo "Please install OpenJDK manually or use a different version"
    return 1
}

# run main
krun::install::openjdk::run "$@"
