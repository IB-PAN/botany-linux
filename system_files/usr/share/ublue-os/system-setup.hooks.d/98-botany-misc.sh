#!/usr/bin/bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script botany-misc system 1 || exit 0

set -x

# Function to append a group entry to /etc/group
append_group() {
	local group_name="$1"
	if ! grep -q "^$group_name:" /etc/group; then
		echo "Appending $group_name to /etc/group"
		grep "^$group_name:" /usr/lib/group | tee -a /etc/group >/dev/null
	fi
}

# fix Samba usershares
append_group usershares
