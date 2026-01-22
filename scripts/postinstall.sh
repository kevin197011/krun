#!/usr/bin/env bash
# Copyright (c) 2025 kk
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

# Add krun to PATH if not already present
if [ -f /etc/profile.d/krun.sh ]; then
    exit 0
fi

echo '# krun PATH configuration' >/etc/profile.d/krun.sh
echo 'export PATH="$PATH:/usr/local/bin"' >>/etc/profile.d/krun.sh
chmod 644 /etc/profile.d/krun.sh
