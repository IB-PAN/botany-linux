#!/usr/bin/bash

checksum=$(sha256sum /usr/share/ublue-os/system-flatpaks.list | md5sum | awk '{print $1}')

source /usr/lib/ublue/setup-services/libsetup.sh

version-script flatpaks-botany system 5-$checksum || exit 0

set -x

function run {
    # needs working network and DNS
    while true; do
        if [[ $(systemctl is-active network-online.target) == "active" ]]; then
            nslookup -timeout=2 -retry=0 example.com >/dev/null 2>&1
            dns_status=$?
            if [[ $dns_status == 0 ]]; then
                break
            fi
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
