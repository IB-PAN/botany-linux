#!/usr/bin/bash

checksum=$(sha256sum \
	/usr/share/botany/firefox-* \
	/usr/share/botany/chromium-* \
	/usr/share/ublue-os/firefox-config/* \
	| md5sum | awk '{print $1}')

source /usr/lib/ublue/setup-services/libsetup.sh

version-script flatpaks-botany-post system 2-$checksum || exit 0

set -x

ARCH=$(arch)
if [ "$ARCH" != "aarch64" ] ; then
	# Set up Firefox policies

	mkdir -p "/var/lib/flatpak/extension/org.mozilla.firefox.systemconfig/${ARCH}/stable/policies"
	cp -f /usr/share/botany/firefox-policies.json "/var/lib/flatpak/extension/org.mozilla.firefox.systemconfig/${ARCH}/stable/policies/policies.json"

	mkdir -p "/var/lib/flatpak/extension/org.mozilla.firefox.systemconfig/${ARCH}/stable/defaults/pref"
	rm -f "/var/lib/flatpak/extension/org.mozilla.firefox.systemconfig/${ARCH}/stable/defaults/pref/*aurora*.js"
	rm -f "/var/lib/flatpak/extension/org.mozilla.firefox.systemconfig/${ARCH}/stable/defaults/pref/*botany*.js"
	cp -rf /usr/share/ublue-os/firefox-config/* "/var/lib/flatpak/extension/org.mozilla.firefox.systemconfig/${ARCH}/stable/defaults/pref/"

	# https://github.com/IB-PAN/botany-browser-extension-linux
	cp -f /usr/share/botany/firefox-extension.xpi "/var/lib/flatpak/extension/org.mozilla.firefox.systemconfig/${ARCH}/stable/firefox-extension.xpi"

	# Set up Chromium policies

	mkdir -p "/var/lib/flatpak/extension/org.chromium.Chromium.Extension.systemconfig/${ARCH}/1/policies/managed"
	cp -f /usr/share/botany/chromium-policies.json "/var/lib/flatpak/extension/org.chromium.Chromium.Extension.systemconfig/${ARCH}/1/policies/managed/policies.json"

	# https://developer.chrome.com/docs/extensions/how-to/distribute/install-extensions#prereq-crx
	#mkdir -p "/var/lib/flatpak/extension/org.chromium.Chromium.Extension.systemconfig/${ARCH}/1/extensions"
	#cp -f /usr/share/botany/chromium-extension.crx "/var/lib/flatpak/extension/org.chromium.Chromium.Extension.systemconfig/${ARCH}/1/extensions/chromium-extension.crx"
	##echo '{ "external_crx": "/etc/chromium/extensions/chromium-extension.crx", "external_version": "1.0" }' > "/var/lib/flatpak/extension/org.chromium.Chromium.Extension.systemconfig/${ARCH}/1/extensions/aaabbbcccdddeeefff.json"
	# actually try adding this to chromium-policies.json instead:
	# "ExtensionSettings": { "aaabbbcccdddeeefff": { "installation_mode": "force_installed", "update_url": "file:///etc/chromium/extensions/chromium-extension.crx", "override_update_url": true } },
fi
