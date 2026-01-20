#!/usr/bin/bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script botany-misc system 4 || exit 0

set -x

# Function to append a group entry to /etc/group
append_group() {
	local group_name="$1"
	if ! grep -q "^$group_name:" /etc/group; then
		echo "Appending $group_name to /etc/group"
		grep "^$group_name:" /usr/lib/group | tee -a /etc/group >/dev/null
	fi
}

append_group usershares
append_group libvirt

# Remove Homebrew remnants
rm -rf /var/home/linuxbrew /var/lib/homebrew /var/cache/homebrew \
	/etc/.linuxbrew /etc/profile.d/brew{,-bash-completion}.sh /etc/security/limits.d/30-brew-limits.conf \
	/etc/systemd/system/{default,multi-user}.target.wants/brew-setup.service \
    /etc/systemd/system/timers.target.wants/brew-{update,upgrade}.timer

# Remove duperemove database if it was made before the period where it was overly inflated
if [ -d /var/lib/duperemove ]; then
	find /var/lib/duperemove -name '-var-home.hashfile*' -exec bash -c 'LC_ALL=C stat "$0" | grep -qF "Birth: 2025-" && rm -f "$0"' {} \;
fi
