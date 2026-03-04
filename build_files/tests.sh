#!/usr/bin/bash

echo "::group:: ===$(basename "$0")==="

set -eoux pipefail

# branding related changes
test -f /usr/share/icons/ibpan-logo.svg
test -d /usr/share/plasma/look-and-feel/pl.botany.desktop
cmp --silent /usr/share/icons/ibpan-logo.svg /usr/share/icons/hicolor/scalable/distributor-logo.svg

# Secure Boot and kernel
test -f /etc/pki/akmods/certs/botany.der
sbverify --list /usr/lib/modules/*/vmlinuz | grep -qF '/C=PL/L=Krakow/O=Instytut Botaniki PAN/OU=Botany Secure Boot/CN=botany'

xmllint --noout \
  /usr/share/backgrounds/default.xml \
  /usr/lib/naps2/appsettings.xml \
  /usr/share/fontconfig/conf.avail/99-botany.conf

JSON_FILES=(
    /usr/lib/ostree/auth.json
    /usr/share/wallpapers/ibpan_logo/metadata.json
    /usr/share/plasma/look-and-feel/pl.botany.desktop/metadata.json
    /usr/share/botany/firefox-policies.json
    /usr/libexec/rstudio/package.json
)
for file in "${JSON_FILES[@]}"; do
    test -f "$file" || { echo "Missing JSON file: ${file}... Exiting"; exit 1 ; }
    ( cat "$file" | jq -j 'empty' ) || { echo "Corrupted JSON file: ${file}... Exiting"; exit 1 ; }
done

DESKTOP_FILES=(
    /etc/xdg/autostart/sigillum_monitor.desktop
    /usr/share/applications/openrefine.desktop
    /usr/share/applications/rstudio.desktop
)
#/usr/share/applications/org.kde.discover{,.flatpak,.notifier,.urlhandler}.desktop
for file in "${DESKTOP_FILES[@]}"; do
    test -f "$file" || { echo "Missing desktop file: ${file}... Exiting"; exit 1 ; }
    ( desktop-file-validate "$file" ) || { echo "Corrupted desktop file: ${file}... Exiting"; exit 1 ; }
done

# Make sure this garbage never makes it to an image
if [ -f /usr/lib/systemd/system/flatpak-add-fedora-repos.service ]; then exit 1; fi

# Make sure Homebrew was removed (https://github.com/ublue-os/brew)
(
    if [ -f /etc/profile.d/brew-bash-completion.sh ]; then exit 1; fi
    if [ -f /etc/profile.d/brew.sh ]; then exit 1; fi
    if [ -f /etc/security/limits.d/30-brew-limits.conf ]; then exit 1; fi
    if [ -f /usr/lib/systemd/system-preset/01-homebrew.preset ]; then exit 1; fi
    if [ -f /usr/lib/systemd/system/brew-setup.service ]; then exit 1; fi
    if [ -f /usr/lib/systemd/system/brew-update.service ]; then exit 1; fi
    if [ -f /usr/lib/systemd/system/brew-update.timer ]; then exit 1; fi
    if [ -f /usr/lib/systemd/system/brew-upgrade.service ]; then exit 1; fi
    if [ -f /usr/lib/systemd/system/brew-upgrade.timer ]; then exit 1; fi
    if [ -f /usr/lib/tmpfiles.d/homebrew.conf ]; then exit 1; fi
    if [ -f /usr/share/fish/vendor_conf.d/ublue-brew.fish ]; then exit 1; fi
    if [ -f /usr/share/homebrew.tar.zst ]; then exit 1; fi
) || { echo "Homebrew uninstallation tests failed!"; exit 1 ; }

# hplip-plugin tests
(
    stat /usr/share/hplip/data/firmware/hp_laserjet_100*.fw.gz >/dev/null
    stat /usr/share/hplip/data/firmware/hp_laserjet_p100*.fw.gz >/dev/null
    stat /usr/share/hplip/data/firmware/hp_laserjet_professional_p1*.fw.gz >/dev/null
    stat /usr/share/hplip/prnt/plugins/*.so >/dev/null
    stat /usr/share/hplip/prnt/plugins/*-$(uname -m).so >/dev/null
    stat /usr/share/hplip/scan/plugins/bb_*.so >/dev/null
    stat /usr/share/hplip/scan/plugins/bb_*-$(uname -m).so >/dev/null
    stat /usr/share/hplip/fax/plugins/fax_*.so >/dev/null
    stat /usr/share/hplip/fax/plugins/fax_*-$(uname -m).so >/dev/null
    test -f /usr/share/hplip/plugin.spec
    test -f /usr/share/hplip/hplip.state
    HPLIP_VERSION=$(rpm -q --queryformat '%{VERSION}' hplip-common)
    grep -zPq '\[plugin\][^\[\]]*\ninstalled\s*=\s*1(\n|$)' /usr/share/hplip/hplip.state
    grep -zPq '\[plugin\][^\[\]]*\neula\s*=\s*1(\n|$)' /usr/share/hplip/hplip.state
    grep -zPq "\[plugin\][^\[\]]*\nversion\s*=\s*${HPLIP_VERSION}(\n|$)" /usr/share/hplip/hplip.state
    test -f /usr/lib/tmpfiles.d/hplip.conf
) || { echo "hplip-plugin tests failed!"; exit 1 ; }

# Make sure pam_u2f is enabled
grep -qF 'with-pam-u2f' /etc/authselect/authselect.conf
grep -qF 'pam_u2f.so cue' /etc/pam.d/system-auth
grep -qF 'pam_u2f.so cue' /etc/pam.d/password-auth

# Kopia.io
test -f /opt/KopiaUI/resources/server/kopia
test -L /usr/bin/kopia
/usr/bin/kopia --version | grep -qF "from: kopia/kopia"

# Make sure there's no artifacts from Arch's packages being improperly unpacked
if [[ -e /.BUILDINFO || -e /.MTREE || -e /.PKGINFO ]]; then exit 1; fi

# pdf-xchange
test -e /usr/bin/pdf-xchange
test -d /usr/lib/pdf-xchange
test -f /usr/share/applications/pdf-xchange.desktop

# Check for KDE Plasma version mismatch
# Fedora Repos have gotten the newer one, trying to upgrade
# everything except a few packages, breaking SDDM and shell

KDE_VER="$(rpm -q --qf '%{VERSION}' plasma-desktop)"
# package picked by failures in the past
KSCREEN_VERS="$(rpm -q --qf '%{VERSION}' kscreen)"
KWIN_VERS="$(rpm -q --qf '%{VERSION}' kwin)"

# Doing QT as well just in case, we have a versionlock in main
QT_VER="$(rpm -q --qf '%{VERSION}' qt6-qtbase)"
# Not an important package in itself, just a good indicator
QTFS_VER="$(rpm -q --qf '%{VERSION}' qt6-filesystem)"

if [[ "$KDE_VER" != "$KSCREEN_VERS" || "$KDE_VER" != "$KWIN_VERS" ]]; then
    echo "KDE Version mismatch"
    exit 1
fi

if [[ "$QT_VER" != "$QTFS_VER" ]]; then
    echo "QT Version mismatch"
    exit 1
fi

IMPORTANT_PACKAGES=(
    flatpak
    kwin
    plasma-desktop
    podman
    systemd
    uld
    hplip
    distrobox
)

for package in "${IMPORTANT_PACKAGES[@]}"; do
    rpm -q "${package}" >/dev/null || { echo "Missing package: ${package}... Exiting"; exit 1 ; }
done

# these packages are supposed to be removed
UNWANTED_PACKAGES=(
    akonadi-server
    libkdepim
    fedora-logos
    firefox
    kde-connect
    tailscale
    ptyxis
    fedora-bookmarks
    kcm_ublue
)

for package in "${UNWANTED_PACKAGES[@]}"; do
    if rpm -q "${package}" >/dev/null 2>&1; then
        echo "Unwanted package found: ${package}... Exiting"; exit 1
    fi
done

IMPORTANT_UNITS=(
    swtpm-workaround.service
    ublue-os-libvirt-workarounds.service
    swapspace.service
    scrutiny-collector.timer
    btrfs-scrub.timer
    xfs_scrub_all.timer
    #duperemove-weekly@$(systemd-escape /var/home).timer
    ananicy-cpp.service
)

for unit in "${IMPORTANT_UNITS[@]}"; do
    if ! systemctl is-enabled "$unit" 2>/dev/null | grep -q "^enabled$"; then
        echo "${unit} is not enabled"
        exit 1
    fi
done

echo "::endgroup::"
