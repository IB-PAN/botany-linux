#!/usr/bin/bash

# import env (set -a causes variables to be automatically exported)
set -a
[ -f /.env ] && . /.env
set +a

set -ouex pipefail

source /ctx/build_files/build-helpers.sh

echo "{\"auths\":{\
  \"${IMAGE_REGISTRY}\":{\"auth\":\"`echo -n "${REGISTRY_PULLER_USER}:${REGISTRY_PULLER_PASSWORD}" | base64 -w0`\"},\
  \"${IMAGE_REGISTRY_ALT}\":{\"auth\":\"`echo -n "${REGISTRY_PULLER_USER}:${REGISTRY_PULLER_PASSWORD}" | base64 -w0`\"}\
  }}" | jq | tee /usr/lib/ostree/auth.json

# temporary
mkdir -p /var/roothome/.gpg

# handle /opt
rm -rf /opt /usr/opt
#mkdir -p /usr/opt
#ln -s usr/opt /opt
mkdir -p /opt

rm -f /etc/ublue-os/system-flatpaks*.list

# Consolidate Just Files
find /ctx/just -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >>/usr/share/ublue-os/just/61-botany.just
echo 'import? "/usr/share/ublue-os/just/61-botany.just"' >>/usr/share/ublue-os/just/00-entry.just

# Restore Discover over Bazaar
discover_apps=(org.kde.discover{,.flatpak,.notifier,.urlhandler}.desktop)
for app in "${discover_apps[@]}"; do
    if [ -f "/usr/share/applications/${app}.disabled" ]; then
        mv "/usr/share/applications/${app}.disabled" "/usr/share/applications/${app}"
    fi
done
sed -i 's!^application/vnd.flatpak.ref=io.github.kolunmi.Bazaar.desktop;*$!!g' /usr/share/applications/mimeapps.list

rm -f /usr/share/applications/{documentation,Discourse,dev.getaurora.aurora-docs}.desktop
rm -f /usr/share/kglobalaccel/dev.getaurora.aurora-docs.desktop
rm -f /usr/share/kglobalaccel/org.gnome.Ptyxis.desktop
rm -f /usr/share/doc/aurora/aurora.pdf
rm -rf /usr/share/backgrounds/aurora/aurora-wallpaper-*
rm -rf /usr/share/wallpapers/aurora-wallpaper-*
rm -rf /usr/share/sddm/themes/01-breeze-aurora
rm -rf /usr/share/plasma/look-and-feel/dev.getaurora.aurora.desktop

### Install packages

# these packages are needed for parallel runs
dnf5 install -y moreutils parallel curl zstd xmlstarlet jq yq bc

run_parallel \
    /ctx/build_files/50-packages.sh \
    /ctx/build_files/50-onlyoffice.sh \
    /ctx/build_files/50-naps2.sh \
    /ctx/build_files/50-hplip.sh \
    /ctx/build_files/50-sigillum.sh \
    /ctx/build_files/50-bun.sh \
    /ctx/build_files/50-deno.sh \
    /ctx/build_files/50-fonts.sh \
    /ctx/build_files/50-dlibra.sh \
    /ctx/build_files/50-scrutiny.sh \
    /ctx/build_files/50-beszel.sh

#### Enabling a System Unit File

systemctl enable podman.socket
systemctl enable sshd.service
systemctl enable smb.service
systemctl enable nmb.service

# Allow sharing CUPS printers (port 631) (disabled by default, still needs explicit enablement in settings)
firewall-offline-cmd --service=ipp

# Allow sharing NAPS2 scanners via ESCL/AirScan (https://www.naps2.com/doc/scanner-sharing)
firewall-offline-cmd --port=9801-9850:tcp --port=9901-9950:tcp

# U2F PAM auth (module config is in /etc/security/pam_u2f.conf)
install --owner=root --group=root --mode=400 /ctx/u2f_keys /usr/share/botany/u2f_keys
#authselect enable-feature with-pam-u2f
authselect select --force --nobackup local \
    with-silent-lastlog \
    with-mdns4 \
    with-fingerprint \
    with-pam-u2f
authselect apply-changes

/ctx/build_files/fix_kde_google_integration.sh

run_parallel \
    /ctx/build_files/60-branding.js \
    /ctx/build_files/60-mime_types.js \
    /ctx/build_files/60-fix_libreoffice_pl_icons.sh \
    /ctx/build_files/60-teamviewer.sh \
    /ctx/build_files/60-kernel.sh

# Favorites in Kickoff
sed -i '/<entry name="launchers" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,preferred:\/\/filemanager<\/default>/' /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml

# Starship prompt
rm -f /etc/skel/.config/starship.toml
sed -i '/^eval "$(starship init bash)"$/d' /etc/bashrc # they might remove this soon
if [ -f /etc/profile.d/90-aurora-starship.sh ]; then rm -f /etc/profile.d/90-aurora-starship.sh; fi # they might have this instead of the above
echo 'export STARSHIP_CONFIG=/usr/share/botany/starship.toml' >> /etc/bashrc
echo 'if [[ "$(whoami)" == "root" ]]; then export STARSHIP_CONFIG=/usr/share/botany/starship_root.toml; fi' >> /etc/bashrc
echo 'eval "$(starship init bash)"' >> /etc/bashrc
sed -r "/(success|error)_symbol/s|=.*|= '[#](bold bright-red)'|" /usr/share/botany/starship.toml > /usr/share/botany/starship_root.toml

# Sudo helpers
chown root:root /etc/sudoers.d/botany
chmod 440 /etc/sudoers.d/botany

# Deduplication service
systemctl disable duperemove-weekly@$(systemd-escape /var/home).timer # this is what we used before, now disabled

# Filesystem scrubbing
sed -i \
    -e 's!^BTRFS_SCRUB_MOUNTPOINTS="[^"]*"$!BTRFS_SCRUB_MOUNTPOINTS="auto"!' \
    -e 's!^BTRFS_BALANCE_PERIOD="[^"]*"$!BTRFS_BALANCE_PERIOD="none"!' \
    /etc/sysconfig/btrfsmaintenance
/usr/share/btrfsmaintenance/btrfsmaintenance-refresh-cron.sh systemd-timer
systemctl enable btrfs-scrub.timer
sed -i 's!^OnCalendar=.*$!OnCalendar=monthly\nAccuracySec=1h!' /usr/lib/systemd/system/xfs_scrub_all.timer
systemctl enable xfs_scrub_all.timer

# Hardlink identical files in /usr (--respect-xattrs makes it 8x longer, but it's safer probably?)
# (sha1 instead of sha256 makes it noticeably faster, not using crc32c since it's less secure and actually slower than sha1)
hardlink --ignore-time --method sha1 --respect-xattrs /usr /opt

# Cleanup
rm -rf /tmp/* || true
rm -rf /var/lib/dnf /var/lib/rpm-state /var/roothome /var/opt/* || true
find /var/* -maxdepth 0 -type d \! -name cache \! -name log -exec rm -fr {} \;
find /var/cache/* -maxdepth 0 -type d \! -name libdnf5 \! -name rpm-ostree -exec rm -fr {} \;
find /boot -mindepth 1 -delete
echo "Build script completed!"

/ctx/build_files/tests.sh
