#!/usr/bin/env bash
# Copyright (c) 2026 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
#   curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/deploy.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/deploy.sh | bash -s -- --uninstall
#
# Env:
#   KRUN_VERSION      tag or bare version (v2.2.0 / 2.2.0); default: latest GitHub release
#   KRUN_INSTALL_DIR  install dir (default: ~/.krun/bin, or /usr/local/bin if root + writable)
#   KRUN_REPO         owner/name (default: kevin197011/krun)
#   KRUN_ACTION       install (default) | uninstall

KRUN_REPO="${KRUN_REPO:-kevin197011/krun}"
KRUN_CURL_UA='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 krun/2.2'
KRUN_ACTION="${KRUN_ACTION:-install}"

krun::deploy::log() { printf '%s\n' "$*"; }
krun::deploy::die() { printf '✗ %s\n' "$*" >&2; exit 1; }

krun::deploy::curl() {
    curl -fsSL -A "$KRUN_CURL_UA" "$@"
}

krun::deploy::detect_os() {
    case "$(uname -s 2>/dev/null || echo unknown)" in
        Linux) echo linux ;;
        Darwin) echo darwin ;;
        *) krun::deploy::die "unsupported OS (need Linux or macOS). On Windows: irm https://raw.githubusercontent.com/${KRUN_REPO}/main/deploy.ps1 | iex" ;;
    esac
}

krun::deploy::detect_arch() {
    case "$(uname -m 2>/dev/null || echo unknown)" in
        x86_64 | amd64) echo amd64 ;;
        aarch64 | arm64) echo arm64 ;;
        *) krun::deploy::die "unsupported arch: $(uname -m) (need amd64 or arm64)" ;;
    esac
}

krun::deploy::resolve_version() {
    if [[ -n "${KRUN_VERSION:-}" ]]; then
        local v="$KRUN_VERSION"
        [[ "$v" != v* ]] && v="v${v}"
        echo "$v"
        return
    fi
    local tag
    tag="$(krun::deploy::curl "https://api.github.com/repos/${KRUN_REPO}/releases/latest" \
        | grep -m1 '"tag_name"' \
        | sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')" || true
    [[ -n "$tag" ]] || krun::deploy::die "could not resolve latest release; set KRUN_VERSION=vX.Y.Z"
    echo "$tag"
}

krun::deploy::existing_bin() {
    local p
    if [[ -n "${KRUN_INSTALL_DIR:-}" && -e "${KRUN_INSTALL_DIR}/krun" ]]; then
        printf '%s\n' "${KRUN_INSTALL_DIR}/krun"
        return 0
    fi
    for p in /usr/local/bin/krun "${HOME}/.krun/bin/krun"; do
        [[ -e "$p" ]] || continue
        printf '%s\n' "$p"
        return 0
    done
    if command -v krun >/dev/null 2>&1; then
        command -v krun
        return 0
    fi
    return 1
}

krun::deploy::pick_dir() {
    if [[ -n "${KRUN_INSTALL_DIR:-}" ]]; then
        echo "$KRUN_INSTALL_DIR"
        return
    fi
    # Prefer overwriting an existing install so PATH still hits the new binary.
    local existing dir
    if existing="$(krun::deploy::existing_bin 2>/dev/null)"; then
        dir="$(cd "$(dirname "$existing")" && pwd)"
        if [[ -w "$dir" ]] || [[ -w "$(dirname "$dir")" ]]; then
            echo "$dir"
            return
        fi
    fi
    if [[ "${EUID:-$(id -u)}" -eq 0 ]] && [[ -d /usr/local/bin ]] && [[ -w /usr/local/bin ]]; then
        echo /usr/local/bin
        return
    fi
    echo "${HOME}/.krun/bin"
}

krun::deploy::current_version() {
    local bin="${1:-}"
    [[ -n "$bin" && -x "$bin" ]] || return 0
    "$bin" version 2>/dev/null | head -1 || true
}

krun::deploy::replace_bin() {
    # Atomic-ish overwrite: write to temp beside target, then mv over.
    local src="$1" dest="$2"
    local tmp="${dest}.new.$$"
    install -m 0755 "$src" "$tmp"
    mv -f "$tmp" "$dest"
}

krun::deploy::purge_stale() {
    local keep="$1"
    local p
    for p in /usr/local/bin/krun "${HOME}/.krun/bin/krun"; do
        [[ -e "$p" ]] || continue
        [[ "$p" == "$keep" ]] && continue
        rm -f "$p"
        krun::deploy::log "removed stale $p"
    done
}

krun::deploy::ensure_path() {
    local dir="$1"
    case ":$PATH:" in
        *":$dir:"*) return 0 ;;
    esac
    local rc=""
    if [[ -f "${HOME}/.zshrc" ]]; then
        rc="${HOME}/.zshrc"
    elif [[ -f "${HOME}/.bashrc" ]]; then
        rc="${HOME}/.bashrc"
    else
        rc="${HOME}/.bashrc"
    fi
    if ! grep -Fq "$dir" "$rc" 2>/dev/null; then
        printf '\nexport PATH="%s:$PATH"\n' "$dir" >>"$rc"
        krun::deploy::log "added PATH entry to $rc — run: source $rc"
    fi
}

krun::deploy::strip_path() {
    local dir="$1"
    local rc
    for rc in "${HOME}/.zshrc" "${HOME}/.bashrc" "${HOME}/.profile"; do
        [[ -f "$rc" ]] || continue
        if grep -Fq "$dir" "$rc" 2>/dev/null; then
            # Remove lines that only export PATH with this dir (our installer style).
            local tmp
            tmp="$(mktemp)"
            grep -v -F "$dir" "$rc" >"$tmp" || true
            mv "$tmp" "$rc"
            krun::deploy::log "removed PATH entry from $rc"
        fi
    done
}

krun::deploy::try_package() {
    local os="$1" arch="$2" tag="$3" ver="${3#v}"
    [[ "$os" == linux ]] || return 1
    command -v curl >/dev/null 2>&1 || return 1

    local base="https://github.com/${KRUN_REPO}/releases/download/${tag}"
    local tmp
    tmp="$(mktemp -d)"
    # shellcheck disable=SC2064
    trap "rm -rf '$tmp'" RETURN

    if command -v dpkg >/dev/null 2>&1; then
        local deb="krun_${ver}_${arch}.deb"
        if krun::deploy::curl -o "${tmp}/${deb}" "${base}/${deb}" 2>/dev/null; then
            if dpkg -i "${tmp}/${deb}" 2>/dev/null || apt-get install -y "${tmp}/${deb}" 2>/dev/null; then
                krun::deploy::log "installed via ${deb}"
                return 0
            fi
        fi
    fi
    if command -v rpm >/dev/null 2>&1; then
        local rpm="krun_${ver}_${arch}.rpm"
        if krun::deploy::curl -o "${tmp}/${rpm}" "${base}/${rpm}" 2>/dev/null; then
            if rpm -Uvh "${tmp}/${rpm}" 2>/dev/null || yum install -y "${tmp}/${rpm}" 2>/dev/null || dnf install -y "${tmp}/${rpm}" 2>/dev/null; then
                krun::deploy::log "installed via ${rpm}"
                return 0
            fi
        fi
    fi
    return 1
}

krun::deploy::install_binary() {
    local os="$1" arch="$2" tag="$3" ver="${3#v}"
    local archive="krun_${ver}_${os}_${arch}.tar.gz"
    local url="https://github.com/${KRUN_REPO}/releases/download/${tag}/${archive}"
    local dest
    dest="$(krun::deploy::pick_dir)"
    mkdir -p "$dest"

    local tmp
    tmp="$(mktemp -d)"
    # shellcheck disable=SC2064
    trap "rm -rf '$tmp'" RETURN

    krun::deploy::log "Downloading ${archive}..."
    krun::deploy::curl -o "${tmp}/${archive}" "$url" \
        || krun::deploy::die "download failed: ${url}"

    tar -xzf "${tmp}/${archive}" -C "$tmp" \
        || krun::deploy::die "extract failed"

    local bin=""
    if [[ -f "${tmp}/krun" ]]; then
        bin="${tmp}/krun"
    else
        bin="$(find "$tmp" -type f -name krun | head -1 || true)"
    fi
    [[ -n "$bin" && -f "$bin" ]] || krun::deploy::die "archive missing krun binary"

    local target="${dest}/krun" prev=""
    if [[ -e "$target" ]]; then
        prev="$(krun::deploy::current_version "$target")"
        if [[ -n "$prev" ]]; then
            krun::deploy::log "updating existing install: ${prev} → ${tag}"
        else
            krun::deploy::log "replacing existing ${target}"
        fi
    fi

    krun::deploy::replace_bin "$bin" "$target"
    krun::deploy::purge_stale "$target"
    krun::deploy::log "installed ${target} (${tag}, ${os}/${arch})"

    if [[ "$dest" != /usr/local/bin ]]; then
        krun::deploy::ensure_path "$dest"
    fi

    if [[ -x "$target" ]]; then
        "$target" version || true
    fi
}

krun::deploy::uninstall() {
    local dest removed=0
    dest="$(krun::deploy::pick_dir)"

    if [[ -x "${dest}/krun" ]] || [[ -f "${dest}/krun" ]]; then
        rm -f "${dest}/krun"
        krun::deploy::log "removed ${dest}/krun"
        removed=1
    fi

    # Also remove common locations if present.
    for p in /usr/local/bin/krun "${HOME}/.krun/bin/krun"; do
        if [[ -e "$p" ]]; then
            rm -f "$p"
            krun::deploy::log "removed $p"
            removed=1
        fi
    done

    krun::deploy::strip_path "${HOME}/.krun/bin"
    if [[ -d "${HOME}/.krun/bin" ]] && [[ -z "$(ls -A "${HOME}/.krun/bin" 2>/dev/null || true)" ]]; then
        rmdir "${HOME}/.krun/bin" 2>/dev/null || true
        rmdir "${HOME}/.krun" 2>/dev/null || true
    fi

    # deb/rpm if installed as package
    if command -v dpkg >/dev/null 2>&1 && dpkg -l krun >/dev/null 2>&1; then
        sudo dpkg -r krun 2>/dev/null || dpkg -r krun 2>/dev/null || true
        krun::deploy::log "removed deb package krun (if present)"
        removed=1
    fi
    if command -v rpm >/dev/null 2>&1 && rpm -q krun >/dev/null 2>&1; then
        sudo rpm -e krun 2>/dev/null || rpm -e krun 2>/dev/null || true
        krun::deploy::log "removed rpm package krun (if present)"
        removed=1
    fi

    if [[ "$removed" -eq 0 ]]; then
        krun::deploy::log "krun not found in default locations"
    else
        krun::deploy::log "uninstall done"
    fi
}

krun::deploy::install() {
    command -v curl >/dev/null 2>&1 || krun::deploy::die "curl is required"
    command -v tar >/dev/null 2>&1 || krun::deploy::die "tar is required"

    local os arch tag
    os="$(krun::deploy::detect_os)"
    arch="$(krun::deploy::detect_arch)"
    tag="$(krun::deploy::resolve_version)"

    local existing prev=""
    if existing="$(krun::deploy::existing_bin 2>/dev/null)"; then
        prev="$(krun::deploy::current_version "$existing")"
        if [[ -n "$prev" ]]; then
            krun::deploy::log "found installed krun: ${prev}"
        else
            krun::deploy::log "found installed krun: ${existing}"
        fi
    fi
    krun::deploy::log "Installing krun ${tag} (${os}/${arch}) — will overwrite if present"

    if krun::deploy::try_package "$os" "$arch" "$tag"; then
        # Packages land in /usr/bin or /usr/local/bin; drop user-local stale copy.
        krun::deploy::purge_stale "$(command -v krun 2>/dev/null || echo /usr/local/bin/krun)"
        return 0
    fi
    krun::deploy::install_binary "$os" "$arch" "$tag"
}

krun::deploy::parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --uninstall | -u | uninstall)
                KRUN_ACTION=uninstall
                ;;
            --install | install)
                KRUN_ACTION=install
                ;;
            -h | --help)
                cat <<'EOF'
Usage: deploy.sh [--install|--uninstall]
  --install     install / overwrite-update krun CLI (default)
  --uninstall   remove krun CLI and PATH entries we added
Env: KRUN_VERSION KRUN_INSTALL_DIR KRUN_REPO KRUN_ACTION
EOF
                exit 0
                ;;
            *)
                krun::deploy::die "unknown arg: $1 (try --help)"
                ;;
        esac
        shift
    done
}

krun::deploy::run() {
    krun::deploy::parse_args "$@"
    case "$KRUN_ACTION" in
        uninstall) krun::deploy::uninstall ;;
        install) krun::deploy::install ;;
        *) krun::deploy::die "unknown KRUN_ACTION=$KRUN_ACTION (install|uninstall)" ;;
    esac
}

krun::deploy::run "$@"
