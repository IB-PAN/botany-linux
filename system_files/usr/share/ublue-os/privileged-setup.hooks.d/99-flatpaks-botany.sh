#!/usr/bin/bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script flatpaks-botany privileged 1 || exit 0

set -x

# Set up Firefox policies
ARCH=$(arch)
if [ "$ARCH" != "aarch64" ] ; then
	mkdir -p "/var/lib/flatpak/extension/org.mozilla.firefox.systemconfig/${ARCH}/stable/policies"
	/usr/bin/cp -f /usr/share/botany/firefox-policies.json "/var/lib/flatpak/extension/org.mozilla.firefox.systemconfig/${ARCH}/stable/policies/policies.json"
fi
