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
# Downloads from jdk8_download_url (and fallbacks) when no local tarball is available.

# vars
jdk8_tar_name=${jdk8_tar_name:-jdk-8u481-linux-x64.tar.gz}
jdk8_mirror_base=${jdk8_mirror_base:-https://enos.itcollege.ee/~jpoial/allalaadimised/jdk8}
jdk8_download_url=${jdk8_download_url:-${jdk8_mirror_base}/${jdk8_tar_name}}
jdk8_min_bytes=${jdk8_min_bytes:-50000000}
jdk8_home=${jdk8_home:-/usr/local/java/jdk1.8.0_481}
jdk8_link=${jdk8_link:-/usr/local/java/jdk8}
jdk8_archive_dir=${jdk8_archive_dir:-/usr/local/java/archive}
jdk8_wrapper_bin=${jdk8_wrapper_bin:-/usr/local/bin}
JDK8_TAR=${JDK8_TAR:-}
JDK8_DOWNLOAD_URLS=${JDK8_DOWNLOAD_URLS:-}

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

krun::install::jdk8::file_size() {
    stat -c%s "$1" 2>/dev/null || stat -f%z "$1"
}

krun::install::jdk8::valid_tarball() {
    local file="$1"
    local size

    [[ -f "$file" ]] || return 1
    size="$(krun::install::jdk8::file_size "$file")"
    [[ "$size" -gt "$jdk8_min_bytes" ]]
}

krun::install::jdk8::fetch_url() {
    local url="$1"
    local outfile="$2"

    rm -f "$outfile"
    echo "Trying: ${url}" >&2

    if command -v curl >/dev/null 2>&1; then
        if curl -fsSL --connect-timeout 15 --max-time 900 "$url" -o "$outfile" 2>/dev/null &&
            krun::install::jdk8::valid_tarball "$outfile"; then
            return 0
        fi
        rm -f "$outfile"
    fi

    if command -v wget >/dev/null 2>&1; then
        if wget -q --timeout=15 --tries=1 -O "$outfile" "$url" 2>/dev/null &&
            krun::install::jdk8::valid_tarball "$outfile"; then
            return 0
        fi
        rm -f "$outfile"
    fi

    return 1
}

krun::install::jdk8::download_urls() {
    local -a urls=()
    local url seen deduped=()

    if [[ -n "$JDK8_DOWNLOAD_URLS" ]]; then
        IFS=',' read -r -a urls <<< "$JDK8_DOWNLOAD_URLS"
    fi

    urls+=(
        "$jdk8_download_url"
        "${jdk8_mirror_base}/${jdk8_tar_name}"
        "http://enos.itcollege.ee/~jpoial/allalaadimised/jdk8/${jdk8_tar_name}"
        "https://ghproxy.link/https://enos.itcollege.ee/~jpoial/allalaadimised/jdk8/${jdk8_tar_name}"
    )

    for url in "${urls[@]}"; do
        url="${url#"${url%%[![:space:]]*}"}"
        url="${url%"${url##*[![:space:]]}"}"
        [[ -z "$url" ]] && continue
        for seen in "${deduped[@]:-}"; do
            [[ "$seen" == "$url" ]] && continue 2
        done
        deduped+=("$url")
        echo "$url"
    done
}

krun::install::jdk8::download_tar() {
    local dest="${jdk8_archive_dir}/${jdk8_tar_name}"
    local url

    command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1 || {
        echo "✗ curl or wget is required; install one first" >&2
        return 1
    }

    mkdir -p "$jdk8_archive_dir"

    while IFS= read -r url; do
        if krun::install::jdk8::fetch_url "$url" "${dest}.part"; then
            mv -f "${dest}.part" "$dest"
            echo "✓ Downloaded: ${dest}" >&2
            echo "$dest"
            return 0
        fi
    done < <(krun::install::jdk8::download_urls)

    rm -f "${dest}.part"
    echo "✗ Failed to download ${jdk8_tar_name} from all mirrors" >&2
    echo "  Place the tarball locally and run with JDK8_TAR=/path/to/${jdk8_tar_name}" >&2
    echo "  Or set JDK8_DOWNLOAD_URLS to comma-separated reachable URLs" >&2
    return 1
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
