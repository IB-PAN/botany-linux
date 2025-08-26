#!/usr/bin/bash

checksum=$(sha256sum /usr/share/ublue-os/system-flatpaks*.list | md5sum | awk '{print $1}')

source /usr/lib/ublue/setup-services/libsetup.sh

version-script flatpaks-botany system 8-$checksum || exit 0

set -x

# == removal doesn't need network ==

flatpak list --system --columns=application | grep -Fxf /usr/share/ublue-os/system-flatpaks-remove.list \
    | xargs --no-run-if-empty flatpak --system --force-remove -y uninstall

# remove apps from Fedora Flatpak
flatpak list --system --columns=ref,origin | awk '$2 ~ /^(fedora|fedora-testing)$/ { print $1 }' \
    | xargs --no-run-if-empty flatpak --system --force-remove -y uninstall

# remove unused refs if any exist
flatpak --system --force-remove --unused -y uninstall

# disable Fedora Flatpak remotes
for remote in fedora fedora-testing; do
    if flatpak remotes --system --columns=name | grep -qFx "$remote"; then
        flatpak remote-delete --system --force "$remote"
    fi
done

# == needs working internet and DNS ==
while true; do
    if /usr/share/botany/scripts/is_internet_online.sh; then
        echo "Network online, continuing..."
        break
    fi
    echo "Waiting for network..."
    sleep 1
done

flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo

# --reinstall --or-update
xargs -n 5 flatpak --system -y install < /usr/share/ublue-os/system-flatpaks.list
