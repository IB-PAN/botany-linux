#!/usr/bin/bash

checksum=$(sha256sum /usr/share/botany/firefox-* /usr/share/ublue-os/firefox-config/* | md5sum | awk '{print $1}')

source /usr/lib/ublue/setup-services/libsetup.sh

version-script flatpaks-botany-post system 1-$checksum || exit 0

set -x

# Set up Firefox policies
ARCH=$(arch)
if [ "$ARCH" != "aarch64" ] ; then
	mkdir -p "/var/lib/flatpak/extension/org.mozilla.firefox.systemconfig/${ARCH}/stable/policies"
	/usr/bin/cp -f /usr/share/botany/firefox-policies.json "/var/lib/flatpak/extension/org.mozilla.firefox.systemconfig/${ARCH}/stable/policies/policies.json"

	mkdir -p "/var/lib/flatpak/extension/org.mozilla.firefox.systemconfig/${ARCH}/stable/defaults/pref"
	rm -f "/var/lib/flatpak/extension/org.mozilla.firefox.systemconfig/${ARCH}/stable/defaults/pref/*aurora*.js"
	rm -f "/var/lib/flatpak/extension/org.mozilla.firefox.systemconfig/${ARCH}/stable/defaults/pref/*botany*.js"
	/usr/bin/cp -rf /usr/share/ublue-os/firefox-config/* "/var/lib/flatpak/extension/org.mozilla.firefox.systemconfig/${ARCH}/stable/defaults/pref/"

	# https://github.com/IB-PAN/botany-browser-extension-linux
	/usr/bin/cp -f /usr/share/botany/firefox-extension.xpi "/var/lib/flatpak/extension/org.mozilla.firefox.systemconfig/${ARCH}/stable/firefox-extension.xpi"
fi
