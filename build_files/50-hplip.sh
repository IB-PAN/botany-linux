#!/usr/bin/bash

set -ouex pipefail

source /ctx/build_files/build-helpers.sh

# HPLIP firmware and plugins
gpg --yes --keyserver keyserver.ubuntu.com --recv 82FFA7C6AA7411D934BDE173AC69536A2CF3A243 # HPLIP (HP Linux Imaging and Printing) <hplip@hp.com>
HPLIP_VERSION=$(prpm -q --queryformat '%{VERSION}' hplip-common)
curl --no-progress-meter --retry 3 -Lo /tmp/hplip-plugin.run https://www.openprinting.org/download/printdriver/auxfiles/HP/plugins/hplip-${HPLIP_VERSION}-plugin.run
curl --no-progress-meter --retry 3 -Lo /tmp/hplip-plugin.run.asc https://www.openprinting.org/download/printdriver/auxfiles/HP/plugins/hplip-${HPLIP_VERSION}-plugin.run.asc
gpg --yes --verify /tmp/hplip-plugin.run.asc /tmp/hplip-plugin.run
sh /tmp/hplip-plugin.run --target "/tmp/hplip-plugin-extract" --noexec
curl --no-progress-meter --retry 3 -Lo /tmp/hplip-plugin-extract/scan-plugin-spec.py 'https://raw.githubusercontent.com/archlinux/aur/1c76c4dd3748486b75a3658ad172eeda88e6de3d/scan-plugin-spec.py'

pdnf install hplip hplip-common hplip-libs hplip-gui libsane-hpaio hpijs libusb-compat-0.1

pushd /tmp/hplip-plugin-extract
hplip_install() {
    local line
    while read -r line
    do
        local -a splitted
        readarray -d, -n3 -t splitted <<< "$line"
        splitted[-1]="${splitted[-1]%$'\n'}"
        install -Dvm644 "${splitted[0]}" "/${splitted[1]}"
        if [[ -n "${splitted[2]:-}" ]]
        then
            mkdir -p "$(dirname "${splitted[2]}")"
            ln -srfv "${splitted[1]}" "${splitted[2]}"
        fi
    done < <(CARCH="x86_64" python "./scan-plugin-spec.py" | sort -u)
}
hplip_install
popd
rm -rf /tmp/hplip-plugin{.run,.run.asc,-extract}
install -Dm644 /dev/stdin "/usr/share/hplip/hplip.state" << EOF
[plugin]
installed = 1
eula = 1
version = $HPLIP_VERSION
EOF
