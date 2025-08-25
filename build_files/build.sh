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
rm -rf /opt
mkdir -p /usr/opt
ln -s /usr/opt /opt

rm -f /etc/ublue-os/system-flatpaks*.list

# Consolidate Just Files
find /ctx/just -iname '*.just' -exec printf "\n\n" \; -exec cat {} \; >>/usr/share/ublue-os/just/61-botany.just
echo 'import? "/usr/share/ublue-os/just/61-botany.just"' >>/usr/share/ublue-os/justfile

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

dnf5 -y copr enable ublue-os/staging
dnf5 -y copr enable ublue-os/packages

# this installs a package from fedora repos
dnf5 install -y screen zstd gparted signon-kwallet-extension signon-ui tecla gphoto2 v4l-utils \
    krusader krename kompare md5sum lhasa unrar xz-lzma-compat \
    gnome-commander \
    kcalc gwenview okular kweather haruna kontact kolourpaint qdirstat kdiskmark filelight \
    xmlstarlet duperemove fdupes

dnf5 remove -y kde-connect kde-connect-libs kde-connect-nautilus fcitx fcitx5 input-remapper tailscale ptyxis fedora-bookmarks

# aurora-kde-config aurora-plymouth aurora-backgrounds aurora-cli-logos aurora-fastfetch kcm_ublue
dnf5 remove -y aurora-plymouth aurora-backgrounds aurora-kde-config kcm_ublue
rm -f /usr/share/applications/{documentation,Discourse}.desktop

dnf5 install -y wine q4wine wine-dxvk wine-mono winetricks
dnf5 install -y samba samba-tools

# Virtualization: https://docs.fedoraproject.org/en-US/quick-docs/virtualization-getting-started/
# we don't enable libvirtd service by default
dnf5 group install -y --with-optional virtualization
dnf5 install -y libvirt-nss ublue-os-libvirt-workarounds
systemctl enable swtpm-workaround.service
systemctl enable ublue-os-libvirt-workarounds.service

dnf5 install -y libreoffice libreoffice-help-pl libreoffice-langpack-pl

dnf5 install -y https://github.com/ONLYOFFICE/DesktopEditors/releases/latest/download/onlyoffice-desktopeditors.x86_64.rpm

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
dnf install -y kopia kopia-ui
install -Dm644 <(echo 'eval "$(kopia --completion-script-zsh)"') /usr/share/zsh/site-functions/_kopia
install -Dm644 <(echo 'eval "$(kopia --completion-script-bash)"') /usr/share/bash-completion/completions/kopia
rm /etc/yum.repos.d/kopia.repo

dnf5 config-manager addrepo --from-repofile=https://download.opensuse.org/repositories/home:Alexx2000/Fedora_41/home:Alexx2000.repo --save-filename=Alexx2000
dnf5 install -y doublecmd-qt6
rm /etc/yum.repos.d/Alexx2000.repo

dnf5 install -y https://github.com/cyanfish/naps2/releases/download/v8.2.0/naps2-8.2.0-linux-x64.rpm

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

# dLibra
wget --no-local-db -nc -nv -O /usr/share/icons/dlibra-soft-icon.png https://rcin.org.pl/jnlp2/softIcon.png
dnf5 install -y icedtea-web

# Deduplication service
systemctl enable duperemove-weekly@$(systemd-escape /var/home).timer
# Hardlink identical files in /usr (--respect-xattrs makes it 8x longer, but it's safer probably?)
# (sha1 instead of sha256 makes it noticeably faster, not using crc32c since it's less secure and actually slower than sha1)
hardlink --ignore-time --method sha1 --respect-xattrs /usr

# Sudo helpers
chown root:root /etc/sudoers.d/botany
chmod 440 /etc/sudoers.d/botany
echo 'alias botany_sudo="sudo -u BOTANY_ADM"' >> /etc/bashrc
echo 'alias botany_su="sudo -u BOTANY_ADM su"' >> /etc/bashrc
echo 'alias botany_adm="su - BOTANY_ADM"' >> /etc/bashrc

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
