#!/usr/bin/bash

checksum=$(sha256sum /usr/share/ublue-os/system-flatpaks.list | md5sum | awk '{print $1}')

source /usr/lib/ublue/setup-services/libsetup.sh

version-script flatpaks-botany system 5-$checksum || exit 0

set -x

flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo

# Disable Fedora Flatpak remotes
for remote in fedora fedora-testing; do
    if flatpak remote-list | grep -q "$remote"; then
        flatpak remote-delete "$remote"
    fi
done

# --reinstall --or-update
xargs flatpak --system -y install < /usr/share/ublue-os/system-flatpaks.list
