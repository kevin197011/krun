#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-jdk8.sh | sudo bash
#
# Extract JDK 8 tarball, install java8/javac8 wrappers, leave system java/javac unchanged.
# Downloads from jdk8_download_url when no local tarball is available.

# vars
jdk8_tar_name=${jdk8_tar_name:-jdk-8u481-linux-x64.tar.gz}
jdk8_download_url=${jdk8_download_url:-https://enos.itcollege.ee/~jpoial/allalaadimised/jdk8/${jdk8_tar_name}}
jdk8_home=${jdk8_home:-/usr/local/java/jdk1.8.0_481}
jdk8_link=${jdk8_link:-/usr/local/java/jdk8}
jdk8_archive_dir=${jdk8_archive_dir:-/usr/local/java/archive}
jdk8_wrapper_bin=${jdk8_wrapper_bin:-/usr/local/bin}
JDK8_TAR=${JDK8_TAR:-}

# run code
krun::install::jdk8::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::install::jdk8::centos() {
    krun::install::jdk8::common
}

# debian code
krun::install::jdk8::debian() {
    krun::install::jdk8::common
}

# mac code
krun::install::jdk8::mac() {
    echo "✗ This script only supports Linux x64 offline JDK 8 deployment"
    return 1
}

krun::install::jdk8::download_tar() {
    local dest="${jdk8_archive_dir}/${jdk8_tar_name}"
    local part="${dest}.part"
    local url="${jdk8_download_url}"

    mkdir -p "$jdk8_archive_dir"
    rm -f "$part"

    echo "Downloading: ${url}" >&2
    if command -v wget >/dev/null 2>&1; then
        wget -O "$part" "$url"
    elif command -v curl >/dev/null 2>&1; then
        curl -fL "$url" -o "$part"
    else
        echo "✗ wget or curl is required" >&2
        return 1
    fi

    mv -f "$part" "$dest"
    echo "✓ Downloaded: ${dest}" >&2
    echo "$dest"
}

krun::install::jdk8::resolve_tar() {
    local tar_path="${JDK8_TAR:-${jdk8_archive_dir}/${jdk8_tar_name}}"

    [[ -n "$JDK8_TAR" && -f "$JDK8_TAR" ]] && {
        echo "$JDK8_TAR"
        return 0
    }
    [[ -f "$tar_path" ]] && {
        echo "$tar_path"
        return 0
    }

    krun::install::jdk8::download_tar
}

# common code
krun::install::jdk8::common() {
    [[ "$(id -u)" -eq 0 ]] || {
        echo "✗ Run as root or with sudo"
        return 1
    }

    local tar_path
    tar_path="$(krun::install::jdk8::resolve_tar)" || return 1
    [[ -f "$tar_path" ]] || {
        echo "✗ Tarball not found: ${tar_path}"
        return 1
    }

    mkdir -p /usr/local/java

    if [[ -d "$jdk8_home" ]]; then
        echo "✓ ${jdk8_home} already exists, skipping extract"
    else
        echo "Extracting ${tar_path} -> /usr/local/java/"
        tar -xzf "$tar_path" -C /usr/local/java
        [[ -x "${jdk8_home}/bin/java" ]] || {
            echo "✗ Extract failed: ${jdk8_home}/bin/java not found"
            return 1
        }
    fi

    ln -sfn "$jdk8_home" "$jdk8_link"

    local tool
    for tool in java javac jar jps jstack jmap jcmd keytool; do
        [[ -x "${jdk8_home}/bin/${tool}" ]] &&
            ln -sfn "${jdk8_home}/bin/${tool}" "${jdk8_wrapper_bin}/${tool}8"
    done

    mkdir -p "$jdk8_archive_dir"
    if [[ "$(readlink -f "$tar_path")" != "$(readlink -f "${jdk8_archive_dir}/${jdk8_tar_name}")" ]]; then
        mv -f "$tar_path" "${jdk8_archive_dir}/${jdk8_tar_name}"
        echo "✓ Tarball archived: ${jdk8_archive_dir}/${jdk8_tar_name}"
    fi

    echo "✓ JDK 8 deployment complete"
    java8 -version
}

# run main
krun::install::jdk8::run "$@"
