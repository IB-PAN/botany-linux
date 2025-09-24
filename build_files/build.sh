#!/bin/bash

# import env
set -a
[ -f /.env ] && . /.env
set +a

set -ouex pipefail

echo "{\"auths\":{\"${IMAGE_REGISTRY}\":{\"auth\":\"`echo -n "${REGISTRY_PULLER_USER}:${REGISTRY_PULLER_PASSWORD}" | base64`\"}}}" | tee /usr/lib/ostree/auth.json

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
echo 'import? "/usr/share/ublue-os/just/61-botany.just"' >>/usr/share/ublue-os/justfile

# Restore Discover over Bazaar
discover_apps=(org.kde.discover{,.flatpak,.notifier,.urlhandler}.desktop)
for app in "${discover_apps[@]}"; do
    if [ -f "/usr/share/applications/${app}.disabled" ]; then
        mv "/usr/share/applications/${app}.disabled" "/usr/share/applications/${app}"
    fi
done
sed -i 's!^application/vnd.flatpak.ref=io.github.kolunmi.Bazaar.desktop;*$!!g' /usr/share/applications/mimeapps.list

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

dnf5 -y copr enable ublue-os/staging
dnf5 -y copr enable ublue-os/packages

# this installs a package from fedora repos
dnf5 install -y screen zstd signon-kwallet-extension signon-ui tecla gphoto2 v4l-utils moreutils \
    krusader krename kompare md5sum lhasa unrar xz-lzma-compat \
    gnome-commander \
    kcalc gwenview okular kweather haruna kolourpaint qdirstat kdiskmark filelight cpu-x \
    xmlstarlet jq yq sbsigntools zram-generator stress memtester monitor-edid edid-decode drm_info \
    ripgrep msedit \
    wine q4wine wine-dxvk wine-mono winetricks \
    samba samba-tools \
    gparted gsmartcontrol btrfs-assistant btrfsmaintenance xfsprogs-xfs_scrub \
    curl dialog freerdp git iproute libnotify nmap-ncat iperf3

dnf5 remove -y kde-connect kde-connect-libs kde-connect-nautilus fcitx fcitx5 input-remapper tailscale ptyxis fedora-bookmarks

# aurora-kde-config aurora-plymouth aurora-backgrounds aurora-cli-logos aurora-fastfetch kcm_ublue
dnf5 remove -y aurora-plymouth aurora-backgrounds aurora-kde-config kcm_ublue
rm -f /usr/share/applications/{documentation,Discourse}.desktop

# remove KDE Akonadi/PIM backend/apps, since they take a lot of resources, are finnicky and we don't currently directly need them
dnf5 remove -y akonadi akonadi-server akonadi-calendar akonadi-contacts akonadi-search kdepimlibs-akonadi kdepimlibs libkdepim kdepim kdepim-runtime kontact

# Office suites (LibreOffice + OnlyOffice)
dnf5 install -y libreoffice libreoffice-help-pl libreoffice-langpack-pl
dnf5 install -y https://github.com/ONLYOFFICE/DesktopEditors/releases/latest/download/onlyoffice-desktopeditors.x86_64.rpm

# Virtualization: https://docs.fedoraproject.org/en-US/quick-docs/virtualization-getting-started/
# we don't enable libvirtd service by default
dnf5 group install -y --with-optional virtualization
dnf5 install -y libvirt-nss ublue-os-libvirt-workarounds
systemctl enable swtpm-workaround.service
systemctl enable ublue-os-libvirt-workarounds.service

# swapspace daemon (dynamic swap files creation)
rpm --import https://download.opensuse.org/repositories/home:/Tobi_Peter:/swapspace/openSUSE_Tumbleweed/repodata/repomd.xml.key
dnf5 config-manager addrepo --from-repofile=https://download.opensuse.org/repositories/home:Tobi_Peter:swapspace/openSUSE_Tumbleweed/home:Tobi_Peter:swapspace.repo --save-filename=home_Tobi_Peter_swapspace
dnf5 install -y swapspace
rm /etc/yum.repos.d/home_Tobi_Peter_swapspace.repo
sed -i 's!/usr/local/sbin/swapspace!/usr/sbin/swapspace!' /usr/lib/systemd/system/swapspace.service
systemctl enable swapspace.service

# Double Commander
rpm --import https://download.opensuse.org/repositories/home:/Alexx2000/Fedora_41/repodata/repomd.xml.key
dnf5 config-manager addrepo --from-repofile=https://download.opensuse.org/repositories/home:Alexx2000/Fedora_41/home:Alexx2000.repo --save-filename=home_Alexx2000
dnf5 install -y doublecmd-qt6
rm /etc/yum.repos.d/home_Alexx2000.repo

# kopia.io
rpm --import https://kopia.io/signing-key
tee /etc/yum.repos.d/kopia.repo <<EOF
[Kopia]
name=Kopia
baseurl=http://packages.kopia.io/rpm/stable/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://kopia.io/signing-key
EOF
dnf5 install -y kopia kopia-ui
rm /etc/yum.repos.d/kopia.repo
install -Dm644 <(echo 'eval "$(kopia --completion-script-zsh)"') /usr/share/zsh/site-functions/_kopia
install -Dm644 <(echo 'eval "$(kopia --completion-script-bash)"') /usr/share/bash-completion/completions/kopia

# NAPS2
dnf5 install -y "$(curl -s https://api.github.com/repos/cyanfish/naps2/releases/latest | awk '/naps2-.*-linux-x64.rpm/&&/browser_download_url/{ gsub(/"/, "", $2); print $2 }')"
xmlstarlet edit --inplace --update "/AppConfig/HideDonateButton" --value "true" /usr/lib/naps2/appsettings.xml 2>/dev/null
xmlstarlet edit --inplace --update "/AppConfig/NoUpdatePrompt" --value "true" /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --update "/AppConfig/ShowPageNumbers[@mode='default']" --value "true" /usr/lib/naps2/appsettings.xml 2>/dev/null
xmlstarlet edit --inplace --update "/AppConfig/DefaultProfileSettings/Resolution" --value "Dpi300" /usr/lib/naps2/appsettings.xml 2>/dev/null
xmlstarlet edit --inplace --update "/AppConfig/DefaultProfileSettings/PageSize" --value "A4" /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig" --type elem --name "ImageSettings" /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig/ImageSettings" --type elem --name "DefaultFileName" --value 'skan_$(YYYY)-$(MM)-$(DD).jpg' /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig/ImageSettings" --type elem --name "TiffCompression" --value "Auto" /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig/ImageSettings" --type elem --name "SinglePageTiff" --value "true" /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig" --type elem --name "PdfSettings" /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig/PdfSettings" --type elem --name "DefaultFileName" --value 'skan_$(YYYY)-$(MM)-$(DD).pdf' /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig/PdfSettings" --type elem --name "Metadata" /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig/PdfSettings/Metadata" --type elem --name "Author" --value "Instytut Botaniki PAN" /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig/PdfSettings/Metadata" --type elem --name "Creator" --value "" /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig/PdfSettings/Metadata" --type elem --name "Keywords" --value "" /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig/PdfSettings/Metadata" --type elem --name "Subject" --value "Zeskanowane obrazy" /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig/PdfSettings/Metadata" --type elem --name "Title" --value "Zeskanowane obrazy" /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig/PdfSettings" --type elem --name "SinglePageTiff" --value "true" /usr/lib/naps2/appsettings.xml 2>/dev/null
xmlstarlet edit --inplace --update "/AppConfig/OcrDefaultLanguage" --value "pol+eng" /usr/lib/naps2/appsettings.xml 2>/dev/null
xmlstarlet edit --inplace --update "/AppConfig/ComponentsPath" --value "/usr/lib/naps2/components" /usr/lib/naps2/appsettings.xml 2>/dev/null
mkdir -p /usr/lib/naps2/components/tesseract4
curl --no-progress-meter -Lo /tmp/pol.traineddata.zip https://github.com/cyanfish/naps2-components/releases/download/tesseract-4.0.0b4/pol.traineddata.zip
curl --no-progress-meter -Lo /tmp/eng.traineddata.zip https://github.com/cyanfish/naps2-components/releases/download/tesseract-4.0.0b4/eng.traineddata.zip
unzip /tmp/pol.traineddata.zip -d /usr/lib/naps2/components/tesseract4/
unzip /tmp/eng.traineddata.zip -d /usr/lib/naps2/components/tesseract4/
rm /tmp/{pol,eng}.traineddata.zip

# QDiskInfo
dnf5 copr enable -y birkch/QDiskInfo
dnf5 install -y QDiskInfo
dnf5 copr disable -y birkch/QDiskInfo

# Ookla Speedtest
rpm --import https://packagecloud.io/ookla/speedtest-cli/gpgkey
dnf5 config-manager addrepo --from-repofile="https://packagecloud.io/install/repositories/ookla/speedtest-cli/config_file.repo?os=fedora&dist=36" --save-filename=ookla_speedtest_cli
dnf5 install -y speedtest --repo ookla_speedtest-cli
rm /etc/yum.repos.d/ookla_speedtest_cli.repo

#### Example for enabling a System Unit File

systemctl enable podman.socket
systemctl enable sshd.service
systemctl enable smb.service
systemctl enable nmb.service

# Allow sharing CUPS printers (port 631) (disabled by default, still needs explicit enablement in settings)
firewall-offline-cmd --service=ipp

# Allow sharing NAPS2 scanners via ESCL/AirScan (https://www.naps2.com/doc/scanner-sharing)
firewall-offline-cmd --port=9801-9850:tcp --port=9901-9950:tcp

# bun
wget --no-local-db -nc -nv -O /tmp/bun.zip https://github.com/oven-sh/bun/releases/latest/download/bun-linux-x64-baseline.zip
7z x -o/tmp/ /tmp/bun.zip
rm /tmp/bun.zip
pushd /tmp/bun-linux-*
install -dm755 "completions"
SHELL=zsh "./bun" completions >"completions/bun.zsh"
SHELL=bash "./bun" completions >"completions/bun.bash"
SHELL=fish "./bun" completions >"completions/bun.fish"
install -Dm755 "./bun" "/usr/bin/bun"
ln -s bun "/usr/bin/bunx"
install -Dm644 completions/bun.zsh "/usr/share/zsh/site-functions/_bun"
install -Dm644 completions/bun.bash "/usr/share/bash-completion/completions/bun"
install -Dm644 completions/bun.fish "/usr/share/fish/vendor_completions.d/bun.fish"
popd
rm -rf /tmp/bun-linux-*

# deno
wget --no-local-db -nc -nv -O /tmp/deno.zip https://github.com/denoland/deno/releases/latest/download/deno-x86_64-unknown-linux-gnu.zip
7z x -o/tmp/ /tmp/deno.zip
rm /tmp/deno.zip
install -Dm755 "/tmp/deno" "/usr/bin/deno"
rm /tmp/deno

wget --no-local-db -nc -nv -O /usr/share/icons/teamviewer-dl.svg https://upload.wikimedia.org/wikipedia/commons/3/31/TeamViewer_Logo_Icon_Only.svg

# Branding
#dnf5 -y swap aurora-logos fedora-logos
# Problem: installed package aurora-kde-config-0.1.1-1.fc42.noarch requires aurora-logos, but none of the providers can be installed
bun /ctx/build_files/branding.js

# MS fonts
#git clone --separate-git-dir=$(mktemp -u) --depth=1 https://github.com/pjobson/Microsoft-365-Fonts.git /usr/share/fonts/Microsoft-365-Fonts && rm -rf /usr/share/fonts/Microsoft-365-Fonts/.git/* /usr/share/fonts/Microsoft-365-Fonts/.git
wget --no-local-db -nc -nv -O /tmp/Microsoft-365-Fonts.zip https://github.com/pjobson/Microsoft-365-Fonts/archive/refs/heads/main.zip
7z x -o/usr/share/fonts/ /tmp/Microsoft-365-Fonts.zip
mv /usr/share/fonts/{Microsoft-365-Fonts-main,Microsoft-365-Fonts}
rm /tmp/Microsoft-365-Fonts.zip
chown -R root:root /usr/share/fonts/Microsoft-365-Fonts
chmod -R 644 /usr/share/fonts/Microsoft-365-Fonts
chmod -R a+X /usr/share/fonts/Microsoft-365-Fonts
fc-cache -f -v

/ctx/build_files/fix_kde_google_integration.sh
/ctx/build_files/fix_libreoffice_pl_icons.sh
deno --allow-read --allow-write --allow-env /ctx/build_files/mime_types.js

rm -f /usr/share/kglobalaccel/org.gnome.Ptyxis.desktop

# Favorites in Kickoff
sed -i '/<entry name="launchers" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,preferred:\/\/filemanager<\/default>/' /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml
sed -i '/<entry name="favorites" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,systemsettings.desktop,org.kde.dolphin.desktop,org.kde.krusader.desktop,org.kde.kate.desktop,org.kde.discover.desktop,onlyoffice-desktopeditors.desktop,libreoffice-startcenter.desktop,com.github.IsmaelMartinez.teams_for_linux.desktop,org.kde.plasma-systemmonitor.desktop<\/default>/' /usr/share/plasma/plasmoids/org.kde.plasma.kickoff/contents/config/main.xml

# Starship prompt
rm -f /etc/skel/.config/starship.toml
sed -i '/^eval "$(starship init bash)"$/d' /etc/bashrc
echo 'export STARSHIP_CONFIG=/usr/share/botany/starship.toml' >> /etc/bashrc
echo 'if [[ "$(whoami)" == "root" ]]; then export STARSHIP_CONFIG=/usr/share/botany/starship_root.toml; fi' >> /etc/bashrc
echo 'eval "$(starship init bash)"' >> /etc/bashrc
sed -r "/(success|error)_symbol/s|=.*|= '[#](bold bright-red)'|" /usr/share/botany/starship.toml > /usr/share/botany/starship_root.toml

# Sudo helpers
chown root:root /etc/sudoers.d/botany
chmod 440 /etc/sudoers.d/botany

# dLibra
wget --no-local-db -nc -nv -O /usr/share/icons/dlibra-soft-icon.png https://rcin.org.pl/jnlp2/softIcon.png
dnf5 install -y icedtea-web

# Scrutiny agent
curl --no-progress-meter -Lo /usr/bin/scrutiny-collector-metrics https://github.com/AnalogJ/scrutiny/releases/latest/download/scrutiny-collector-metrics-linux-amd64
chmod +x /usr/bin/scrutiny-collector-metrics
echo "COLLECTOR_API_ENDPOINT=${SCRUTINY_COLLECTOR_API_ENDPOINT}" > /usr/share/botany/scrutiny-collector.env
systemctl enable scrutiny-collector.timer

# Deduplication service
systemctl enable duperemove-weekly@$(systemd-escape /var/home).timer

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
hardlink --ignore-time --method sha1 --respect-xattrs /usr

# Deploy Secure Boot MOK keys
DER_PATH=/etc/pki/akmods/certs/botany.der
cp /ctx/MOK.der "$DER_PATH"
if [ -f "/etc/pki/akmods/certs/akmods-ublue.der" ]; then
    mv /etc/pki/akmods/certs/akmods-ublue.der /etc/pki/akmods/certs/akmods-ublue-original.der
fi
ln -s "$DER_PATH" /etc/pki/akmods/certs/akmods-ublue.der
mkdir -p /usr/share/ublue-os/etc/pki/akmods/certs/
ln -sf "$DER_PATH" /usr/share/ublue-os/etc/pki/akmods/certs/akmods-ublue.der
jq --arg derpath "$DER_PATH" '.["der-path"] = ($derpath)' /etc/ublue-os/setup.json | sponge /etc/ublue-os/setup.json
jq '.["check-secureboot"] = true' /etc/ublue-os/setup.json | sponge /etc/ublue-os/setup.json
systemctl enable check-sb-key.service

# Sign kernel
PUBLIC_KEY_PATH="/ctx/MOK.crt"
PRIVATE_KEY_PATH="/ctx/MOK.key"
KERNEL_SIGN_FILE="/ctx/build_files/sign-file"
for VMLINUZ in /usr/lib/modules/*/vmlinuz; do
    KERNEL=$(basename $(dirname "$VMLINUZ"))
    sbsign --cert "$PUBLIC_KEY_PATH" --key "$PRIVATE_KEY_PATH" "$VMLINUZ" --output "$VMLINUZ"

    # Verify
    sbverify --list "$VMLINUZ"
    if ! sbverify --cert "$PUBLIC_KEY_PATH" "$VMLINUZ"; then
        exit 1
    fi

    # Sign modules
    for module in /usr/lib/modules/"${KERNEL}"/extra/*/*.ko*; do
        module_extension="${module##*.}"
        module_basename="${module%.*}"

        if [[ "$module_extension" == "xz" ]]; then
            xz --decompress --force "$module"
        elif [[ "$module_extension" == "gz" ]]; then
            gzip --decompress --force "$module"
        elif [[ "$module_extension" == "zst" ]]; then
            zstd --decompress --force --rm -T0 "$module"
        elif [[ "$module_extension" == "ko" ]]; then
            module_basename="${module_basename}.ko"
        fi

        "$KERNEL_SIGN_FILE" sha512 "$PRIVATE_KEY_PATH" "$PUBLIC_KEY_PATH" "$module_basename"
        
        if [[ "$module_extension" == "xz" ]]; then
            xz -C crc32 -f "$module_basename"
        elif [[ "$module_extension" == "gz" ]]; then
            gzip -9f "$module_basename"
        elif [[ "$module_extension" == "zst" ]]; then
            zstd -T0 --rm --long -15 "$module_basename"
        fi

        modinfo "$module" | grep -E '^filename:|signer:'
    done
done

# Regenerate initramfs
KERNEL_SUFFIX=""
QUALIFIED_KERNEL="$(rpm -qa | grep -P 'kernel-(|'"$KERNEL_SUFFIX"'-)(\d+\.\d+\.\d+)' | sed -E 's/kernel-(|'"$KERNEL_SUFFIX"'-)//')"
/usr/bin/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible -v --add ostree -f "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
chmod 0600 "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"

# Cleanup
dnf5 -y copr disable ublue-os/staging
dnf5 -y copr disable ublue-os/packages
rm -rf /tmp/* || true
rm -rf /var/lib/dnf /var/lib/rpm-state /var/roothome /var/opt/* || true
find /var/* -maxdepth 0 -type d \! -name cache \! -name log -exec rm -fr {} \;
find /var/cache/* -maxdepth 0 -type d \! -name libdnf5 \! -name rpm-ostree -exec rm -fr {} \;
echo "Build script completed!"
