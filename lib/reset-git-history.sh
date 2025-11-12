#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

set -o errexit
set -o nounset
set -o pipefail

# curl exec:
# curl -fsSL https://raw.githubusercontent.com/kevin197011/krun/main/lib/reset-git-history.sh | bash

# vars
target_branch="${target_branch:-main}"
commit_message="${commit_message:-Initial commit}"

# run code
krun::reset::git-history::run() {
    # default debian platform
    platform='debian'
    command -v yum >/dev/null && platform='centos'
    command -v dnf >/dev/null && platform='centos'
    command -v brew >/dev/null && platform='mac'
    eval "${FUNCNAME/::run/::${platform}}"
}

# centos code
krun::reset::git-history::centos() {
    krun::reset::git-history::common
}

# debian code
krun::reset::git-history::debian() {
    krun::reset::git-history::common
}

# mac code
krun::reset::git-history::mac() {
    krun::reset::git-history::common
}

# common code
krun::reset::git-history::common() {
    # check if git is installed
    if ! command -v git >/dev/null 2>&1; then
        echo "❌ Git is not installed"
        exit 1
    fi

    # check if we are in a git repository
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo "❌ Not a git repository"
        exit 1
    fi

    # display operation information
    echo "⚠️  WARNING: Resetting all git history!"
    echo "   Current branch: $(git branch --show-current)"
    echo "   Target branch: $target_branch"
    echo "   New commit message: $commit_message"
    echo ""

    # checkout to target branch
    echo "Checking out to $target_branch..."
    git checkout "$target_branch"

    # reset to single commit
    echo "Resetting git history..."
    git reset "$(git commit-tree HEAD^{tree} -m "$commit_message")"

    # force push to origin
    echo "Force pushing to origin/$target_branch..."
    git push origin "$target_branch" --force

    echo "✅ Git history has been reset successfully"
    echo "   New commit: $(git log --oneline -1)"
}

# run main
krun::reset::git-history::run "$@"
