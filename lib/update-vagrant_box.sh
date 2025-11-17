#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/update-vagrant_box.sh | bash

# vars
force_update=${force_update:-false}

# run code
krun::update::vagrant_box::run() {
    local platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::update::vagrant_box::centos() {
    echo "Updating Vagrant boxes on CentOS/RHEL..."
    krun::update::vagrant_box::common
}

# debian code
krun::update::vagrant_box::debian() {
    echo "Updating Vagrant boxes on Debian/Ubuntu..."
    krun::update::vagrant_box::common
}

# mac code
krun::update::vagrant_box::mac() {
    echo "Updating Vagrant boxes on macOS..."
    krun::update::vagrant_box::common
}

# check if vagrant is installed
krun::update::vagrant_box::check_vagrant() {
    if ! command -v vagrant >/dev/null 2>&1; then
        echo "✗ Vagrant not found. Please install Vagrant first:"
        echo "  curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/install-vagrant-virtualbox.sh | bash"
        return 1
    fi
    echo "✓ Vagrant found: $(vagrant --version)"
}

# get outdated boxes
krun::update::vagrant_box::get_outdated_boxes() {
    echo "Checking for outdated boxes..."
    vagrant box outdated --global 2>/dev/null | grep -E "outdated|up to date" || {
        echo "No boxes found or error checking for updates"
        return 1
    }
}

# update specific box
krun::update::vagrant_box::update_box() {
    local box_name="$1"
    echo "Updating box: $box_name"

    # Get current versions
    local current_versions=$(vagrant box list | grep "$box_name" | cut -d ',' -f 2 | tr -d ' )' | tr '\n' ' ')

    # Add latest version
    echo "Adding latest version of $box_name..."
    vagrant box add --clean "$box_name" || {
        echo "⚠ Failed to add latest version of $box_name"
        return 1
    }

    # Remove old versions
    if [[ -n "$current_versions" ]]; then
        echo "Removing old versions: $current_versions"
        for version in $current_versions; do
            vagrant box remove "$box_name" -f --box-version="$version" 2>/dev/null || echo "⚠ Failed to remove version $version"
        done
    fi

    echo "✓ Successfully updated $box_name"
}

# common code
krun::update::vagrant_box::common() {
    # Check if vagrant is installed
    krun::update::vagrant_box::check_vagrant || return 1

    # Get list of outdated boxes
    local outdated_output=$(vagrant box outdated --global 2>/dev/null)
    local outdated_boxes=$(echo "$outdated_output" | grep "outdated" | tr -d "*'" | cut -d ' ' -f 2)

    if [[ -z "$outdated_boxes" ]]; then
        echo "✓ All boxes are up to date!"
        krun::update::vagrant_box::show_status
        return 0
    fi

    echo "Found outdated boxes:"
    echo "$outdated_boxes" | while read -r box; do
        echo "  - $box"
    done
    echo ""

    # Update each outdated box
    local updated_count=0
    echo "$outdated_boxes" | while read -r box; do
        if [[ -n "$box" ]]; then
            krun::update::vagrant_box::update_box "$box"
            ((updated_count++))
        fi
    done

    echo ""
    echo "✓ Updated $updated_count box(es)"
    krun::update::vagrant_box::show_status
}

# show current box status
krun::update::vagrant_box::show_status() {
    echo ""
    echo "=== Current Box Status ==="
    vagrant box list 2>/dev/null || echo "No boxes installed"

    echo ""
    echo "=== Outdated Check ==="
    vagrant box outdated --global 2>/dev/null || echo "Error checking for outdated boxes"
}

# run main
krun::update::vagrant_box::run "$@"
