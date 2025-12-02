#!/bin/bash

# import env
set -a
[ -f /.env ] && . /.env
set +a

set -ouex pipefail

source /ctx/build_files/copr-helpers.sh

echo "{\"auths\":{\"${IMAGE_REGISTRY}\":{\"auth\":\"`echo -n "${REGISTRY_PULLER_USER}:${REGISTRY_PULLER_PASSWORD}" | base64 -w0`\"}}}" | tee /usr/lib/ostree/auth.json

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

# this installs a package from fedora repos
dnf5 install -y screen zstd signon-kwallet-extension signon-ui tecla gphoto2 v4l-utils moreutils xlsclients \
    krusader krename kompare md5sum lhasa unrar xz-lzma-compat \
    gnome-commander doublecmd-qt6 \
    kcalc gwenview okular kweather krecorder haruna kolourpaint qdirstat kdiskmark filelight cpu-x audacity \
    xmlstarlet jq yq bc sbsigntools zram-generator stress memtester monitor-edid edid-decode drm_info \
    ripgrep msedit \
    wine q4wine wine-dxvk wine-mono winetricks \
    samba samba-tools \
    gparted gsmartcontrol btrfs-assistant btrfsmaintenance snapper xfsprogs-xfs_scrub duperemove fdupes \
    curl dialog freerdp git iproute libnotify nmap-ncat iperf3 \
    tesseract-langpack-pol tesseract-langpack-eng \
    hplip hplip-common hplip-libs hplip-gui libsane-hpaio hpijs libusb-compat-0.1 sane-backends sane-airscan

dnf5 remove -y kde-connect kde-connect-libs kde-connect-nautilus fcitx fcitx5 input-remapper tailscale ptyxis fedora-bookmarks dosbox-staging

dnf5 remove -y kcm_ublue
rm -f /usr/share/applications/{documentation,Discourse,dev.getaurora.aurora-docs}.desktop
rm -f /usr/share/kglobalaccel/dev.getaurora.aurora-docs.desktop
rm -f /usr/share/doc/aurora/aurora.pdf
rm -rf /usr/share/backgrounds/aurora/aurora-wallpaper-*
rm -rf /usr/share/wallpapers/aurora-wallpaper-*
rm -rf /usr/share/sddm/themes/01-breeze-aurora
rm -rf /usr/share/plasma/look-and-feel/dev.getaurora.aurora.desktop

# remove KDE Akonadi/PIM backend/apps, since they take a lot of resources, are finnicky and we don't currently directly need them
dnf5 remove -y akonadi akonadi-server akonadi-calendar akonadi-contacts akonadi-search kdepimlibs-akonadi kdepimlibs libkdepim kdepim kdepim-runtime kontact

# Office suites (LibreOffice)
dnf5 install -y libreoffice libreoffice-help-pl libreoffice-langpack-pl

# Office suites (OnlyOffice)
# TODO: next package after 2025-12-01 should fix the digest issue...
echo -e '%_pkgverify_level none\n%_pkgverify_flags 0x0' >> /root/.rpmmacros
dnf5 install -y --nogpgcheck https://github.com/ONLYOFFICE/DesktopEditors/releases/latest/download/onlyoffice-desktopeditors.x86_64.rpm
rm -f /root/.rpmmacros

# Virtualization: https://docs.fedoraproject.org/en-US/quick-docs/virtualization-getting-started/
# we don't enable libvirtd service by default
dnf5 group install -y --with-optional virtualization
dnf5 install -y libvirt-nss
copr_install_isolated "ublue-os/packages" "ublue-os-libvirt-workarounds"
systemctl enable swtpm-workaround.service
systemctl enable ublue-os-libvirt-workarounds.service

# swapspace daemon (dynamic swap files creation)
rpm --import https://download.opensuse.org/repositories/filesystems/openSUSE_Tumbleweed/repodata/repomd.xml.key
dnf5 config-manager addrepo --from-repofile=https://download.opensuse.org/repositories/filesystems/openSUSE_Tumbleweed/filesystems.repo --save-filename=openSUSE_Tumbleweed_filesystems
sed -i "s/enabled=.*/enabled=0/g" /etc/yum.repos.d/openSUSE_Tumbleweed_filesystems.repo
dnf5 install -y --from-repo=filesystems swapspace
sed -i 's!/usr/local/sbin/swapspace!/usr/sbin/swapspace!' /usr/lib/systemd/system/swapspace.service
systemctl enable swapspace.service

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
sed -i "s/enabled=.*/enabled=0/g" /etc/yum.repos.d/kopia.repo
dnf5 install -y --from-repo=Kopia kopia kopia-ui
install -Dm644 <(echo 'eval "$(kopia --completion-script-zsh)"') /usr/share/zsh/site-functions/_kopia
install -Dm644 <(echo 'eval "$(kopia --completion-script-bash)"') /usr/share/bash-completion/completions/kopia
rm -f /opt/KopiaUI/resources/app-update.yml

# NAPS2
dnf5 install -y --nogpgcheck "$(curl -s https://api.github.com/repos/cyanfish/naps2/releases/latest | awk '/naps2-.*-linux-x64.rpm/&&/browser_download_url/{ gsub(/"/, "", $2); print $2 }')"
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
mkdir -p /usr/lib/naps2/components/tesseract4/{best,fast}
curl --no-progress-meter -Lo /usr/lib/naps2/components/tesseract4/best/pol.traineddata https://github.com/tesseract-ocr/tessdata_best/raw/refs/heads/main/pol.traineddata
curl --no-progress-meter -Lo /usr/lib/naps2/components/tesseract4/best/eng.traineddata https://github.com/tesseract-ocr/tessdata_best/raw/refs/heads/main/eng.traineddata
ln -sf /usr/share/tesseract/tessdata/pol.traineddata /usr/lib/naps2/components/tesseract4/fast/pol.traineddata
ln -sf /usr/share/tesseract/tessdata/eng.traineddata /usr/lib/naps2/components/tesseract4/fast/eng.traineddata

# HPLIP firmware and plugins
HPLIP_VERSION=$(rpm -q --queryformat '%{VERSION}' hplip)
curl --no-progress-meter -Lo /tmp/hplip-plugin.run https://www.openprinting.org/download/printdriver/auxfiles/HP/plugins/hplip-${HPLIP_VERSION}-plugin.run
sh /tmp/hplip-plugin.run --target "/tmp/hplip-plugin-extract" --noexec
curl --no-progress-meter -Lo /tmp/hplip-plugin-extract/scan-plugin-spec.py 'https://raw.githubusercontent.com/archlinux/aur/1c76c4dd3748486b75a3658ad172eeda88e6de3d/scan-plugin-spec.py'
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
rm -rf /tmp/hplip-plugin{.run,-extract}
install -Dm644 /dev/stdin "/usr/share/hplip/hplip.state" << EOF
[plugin]
installed = 1
eula = 1
version = $HPLIP_VERSION
EOF

# Samsung Unified Linux Driver (printers)
dnf5 config-manager addrepo --from-repofile=https://negativo17.org/repos/fedora-uld.repo --save-filename=negativo17-fedora-uld
sed -i "s/enabled=.*/enabled=0/g" /etc/yum.repos.d/negativo17-fedora-uld.repo
dnf5 install -y --from-repo=fedora-uld uld
firewall-offline-cmd --service=uld

# QDiskInfo
copr_install_isolated "birkch/QDiskInfo" "QDiskInfo"

# kio-onedrive
copr_install_isolated "bernardogn/kio-onedrive" "kio-onedrive"

# Ookla Speedtest
rpm --import https://packagecloud.io/ookla/speedtest-cli/gpgkey
dnf5 config-manager addrepo --from-repofile="https://packagecloud.io/install/repositories/ookla/speedtest-cli/config_file.repo?os=fedora&dist=36" --save-filename=ookla_speedtest_cli
sed -i "s/enabled=.*/enabled=0/g" /etc/yum.repos.d/ookla_speedtest_cli.repo
echo -e '%_pkgverify_level none\n%_pkgverify_flags 0x0' >> /root/.rpmmacros
dnf5 install -y --nogpgcheck --from-repo=ookla_speedtest-cli speedtest
rm -f /root/.rpmmacros

# Sigillum
SIGILLUM_SIGN_VERSION="1.11.31"
SIGILLUM_MANAGER_VERSION="1.0.12"
curl --no-progress-meter -Lo /tmp/Sigillum.run https://sigillum.pl/binaries/content/assets/Pliki/Sigillum_sign_od_2022/Linux/Sigillum_${SIGILLUM_SIGN_VERSION}.run
curl --no-progress-meter -Lo /tmp/Sigman.run https://sigillum.pl/binaries/content/assets/Pliki/Sigman/Linux/Sigman_${SIGILLUM_MANAGER_VERSION}.run
chmod +x /tmp/{Sigillum,Sigman}.run
/tmp/Sigillum.run --confirm-command --accept-licenses --default-answer --auto-answer OverwriteTargetDirectory=Yes,installationErrorWithCancel=Ignore install
/tmp/Sigman.run --root "/opt/sigman" --confirm-command --accept-licenses --default-answer --auto-answer OverwriteTargetDirectory=Yes,installationErrorWithCancel=Ignore install
rm /tmp/{Sigillum,Sigman}.run
sed -i '/^Version=.*$/d' /etc/xdg/autostart/sigillum_monitor.desktop
desktop-file-edit --set-key=X-GNOME-Autostart-enabled --set-value="false" /etc/xdg/autostart/sigillum_monitor.desktop
desktop-file-edit --set-key=Hidden --set-value="true" /etc/xdg/autostart/sigillum_monitor.desktop
# not sure if the below actually does anything, shrug
# TODO: experiment with those when needed and when having access to a test card
##ln -s /opt/sigman/sigillum-pkcs11-64.so /usr/lib64/pkcs11/sigillum-pkcs11-64.so
##echo -e "module: sigillum-pkcs11-64.so\ntrust-policy: yes" > /usr/share/p11-kit/modules/sigillum.module
##echo -e "\n\nlibrary=/usr/lib64/pkcs11/sigillum-pkcs11-64.so\nname=Sigillum (64 bits)\nNSS=slotParams={0xffffffff=[slotFlags=PublicCerts] 0x0=[slotFlags=PublicCerts] 0x1=[slotFlags=PublicCerts] 0x2=[slotFlags=PublicCerts] 0x3=[slotFlags=PublicCerts] 0x4=[slotFlags=PublicCerts] 0x5=[slotFlags=PublicCerts] 0x6=[slotFlags=PublicCerts] 0x7=[slotFlags=PublicCerts] 0x8=[slotFlags=PublicCerts] 0x9=[slotFlags=PublicCerts] 0xa=[slotFlags=PublicCerts] 0xb=[slotFlags=PublicCerts] 0xc=[slotFlags=PublicCerts] 0xd=[slotFlags=PublicCerts] 0xe=[slotFlags=PublicCerts] 0xf=[slotFlags=PublicCerts]}" >> /etc/pki/nssdb/pkcs11.txt
# ~/.pki/nssdb/pkcs11.txt | ~/.mozilla/firefox/*.default*/pkcs11.txt | ...
# modutil -dbdir sql:$HOME/.pki/nssdb/ -add "eToken" -libfile /usr/lib/libeToken.so

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
# FiraCode Nerd Font
wget --no-local-db -nc -nv -O /tmp/FiraCodeNerdFont.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraCode.zip
mkdir -p /usr/share/fonts/nerd-fonts/FiraCodeNerdFont/
7z x -o/usr/share/fonts/nerd-fonts/FiraCodeNerdFont/ /tmp/FiraCodeNerdFont.zip
rm /tmp/FiraCodeNerdFont.zip
chown -R root:root /usr/share/fonts/nerd-fonts/
chmod -R 644 /usr/share/fonts/nerd-fonts/
chmod -R a+X /usr/share/fonts/nerd-fonts/
fc-cache -f -v

/ctx/build_files/fix_kde_google_integration.sh
/ctx/build_files/fix_libreoffice_pl_icons.sh
deno --allow-read --allow-write --allow-env /ctx/build_files/mime_types.js

rm -f /usr/share/kglobalaccel/org.gnome.Ptyxis.desktop

# Favorites in Kickoff
sed -i '/<entry name="launchers" type="StringList">/,/<\/entry>/ s/<default>[^<]*<\/default>/<default>preferred:\/\/browser,preferred:\/\/filemanager<\/default>/' /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/config/main.xml

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
rm -rf /tmp/* || true
rm -rf /var/lib/dnf /var/lib/rpm-state /var/roothome /var/opt/* || true
find /var/* -maxdepth 0 -type d \! -name cache \! -name log -exec rm -fr {} \;
find /var/cache/* -maxdepth 0 -type d \! -name libdnf5 \! -name rpm-ostree -exec rm -fr {} \;
echo "Build script completed!"
