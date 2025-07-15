#!/usr/bin/bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script flatpaks-botany system 2 || exit 0

set -x

flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo

# Disable Fedora Flatpak remotes
for remote in fedora fedora-testing; do
    if flatpak remote-list | grep -q "$remote"; then
        flatpak remote-delete "$remote"
    fi
done

# --reinstall --or-update
xargs flatpak --system -y install < /etc/ublue-os/system-flatpaks.list
