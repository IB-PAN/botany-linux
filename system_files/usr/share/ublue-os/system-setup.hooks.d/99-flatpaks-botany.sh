#!/usr/bin/bash

checksum=$(sha256sum /usr/share/ublue-os/system-flatpaks*.list | md5sum | awk '{print $1}')

source /usr/lib/ublue/setup-services/libsetup.sh

version-script flatpaks-botany system 6-$checksum || exit 0

set -x

function run {
    # removal doesn't need network
    flatpak list --system --columns=application | grep -Fxf /usr/share/ublue-os/system-flatpaks-remove.list \
        | xargs --no-run-if-empty flatpak --system --force-remove -y uninstall

    # needs working internet and DNS
    while true; do
        if /usr/share/botany/scripts/is_internet_online.sh; then
            break
        fi
        sleep 1
    done

    flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo

    # Disable Fedora Flatpak remotes
    for remote in fedora fedora-testing; do
        if flatpak remote-list | grep -q "$remote"; then
            flatpak remote-delete "$remote"
        fi
    done

    # --reinstall --or-update
    xargs flatpak --system -y install < /usr/share/ublue-os/system-flatpaks.list
}

if [ $(systemctl is-active network-online.target) == "active" ]; then
    run
else
    echo "Waiting for network..."
    run &
fi
