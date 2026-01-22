#!/bin/bash
# Add krun to PATH if not already present
if [ -f /etc/profile.d/krun.sh ]; then
    exit 0
fi

echo '# krun PATH configuration' >/etc/profile.d/krun.sh
echo 'export PATH="$PATH:/usr/local/bin"' >>/etc/profile.d/krun.sh
chmod 644 /etc/profile.d/krun.sh
