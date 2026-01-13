#!/usr/bin/bash

set -ouex pipefail

source /ctx/build_files/build-helpers.sh

pdnf install screen signon-kwallet-extension signon-ui tecla gphoto2 v4l-utils xlsclients nodejs \
    krusader krename kompare md5sum lhasa unrar xz-lzma-compat \
    pam-u2f pamu2fcfg fido2-tools yubikey-manager fprintd fprintd-pam \
    gnome-commander doublecmd-qt6 \
    kcalc gwenview okular kweather krecorder haruna kolourpaint kcolorchooser qdirstat kdiskmark filelight cpu-x audacity \
    sbsigntools zram-generator stress stress-ng memtester monitor-edid edid-decode drm_info rocm-smi igt-gpu-tools \
    ripgrep msedit \
    wine q4wine wine-dxvk wine-mono winetricks \
    samba samba-tools \
    gparted gsmartcontrol btrfs-assistant btrfsmaintenance snapper xfsprogs-xfs_scrub duperemove fdupes ncdu \
    dialog freerdp git iproute libnotify nmap-ncat iperf3 podman-compose \
    tesseract-langpack-pol tesseract-langpack-eng \
    sane-backends sane-airscan \
    orca speech-dispatcher espeak-ng speech-dispatcher-espeak-ng qt6-qtspeech qt6-qtspeech-speechd qt5-qtspeech qt5-qtspeech-speechd

pdnf remove kde-connect kde-connect-libs kde-connect-nautilus fcitx fcitx5 input-remapper tailscale ptyxis dosbox-staging \
    fedora-bookmarks kcm_ublue

# Remove Homebrew
rm -f /etc/profile.d/brew-bash-completion.sh \
    /etc/profile.d/brew.sh \
    /etc/security/limits.d/30-brew-limits.conf \
    /usr/lib/systemd/system-preset/01-homebrew.preset \
    /usr/lib/systemd/system/brew-setup.service \
    /usr/lib/systemd/system/brew-update.service \
    /usr/lib/systemd/system/brew-update.timer \
    /usr/lib/systemd/system/brew-upgrade.service \
    /usr/lib/systemd/system/brew-upgrade.timer \
    /usr/lib/tmpfiles.d/homebrew.conf \
    /usr/share/fish/vendor_conf.d/ublue-brew.fish \
    /usr/share/homebrew.tar.zst
rm -f /etc/systemd/system/{default,multi-user}.target.wants/brew-setup.service \
    /etc/systemd/system/timers.target.wants/brew-{update,upgrade}.timer

# remove KDE Akonadi/PIM backend/apps, since they take a lot of resources, are finnicky and we don't currently directly need them
pdnf remove akonadi akonadi-server akonadi-calendar akonadi-contacts akonadi-search kdepimlibs-akonadi kdepimlibs libkdepim kdepim kdepim-runtime kdepim-addons kontact

# Office suites (LibreOffice)
pdnf install libreoffice libreoffice-help-pl libreoffice-langpack-pl

# Virtualization: https://docs.fedoraproject.org/en-US/quick-docs/virtualization-getting-started/
# we don't enable libvirtd service by default
pdnf group install --with-optional virtualization
pdnf install libvirt-nss
copr_install_isolated "ublue-os/packages" "ublue-os-libvirt-workarounds"
systemctl enable swtpm-workaround.service
systemctl enable ublue-os-libvirt-workarounds.service

# swapspace daemon (dynamic swap files creation)
rpm --import https://download.opensuse.org/repositories/filesystems/openSUSE_Tumbleweed/repodata/repomd.xml.key
pdnf config-manager addrepo --from-repofile=https://download.opensuse.org/repositories/filesystems/openSUSE_Tumbleweed/filesystems.repo --save-filename=openSUSE_Tumbleweed_filesystems
sed -i "s/enabled=.*/enabled=0/g" /etc/yum.repos.d/openSUSE_Tumbleweed_filesystems.repo
pdnf install --from-repo=filesystems swapspace
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
pdnf install --from-repo=Kopia kopia-ui
ln -s /opt/KopiaUI/resources/server/kopia /usr/bin/kopia
install -Dm644 <(echo 'eval "$(kopia --completion-script-zsh)"') /usr/share/zsh/site-functions/_kopia
install -Dm644 <(echo 'eval "$(kopia --completion-script-bash)"') /usr/share/bash-completion/completions/kopia
rm -f /opt/KopiaUI/resources/app-update.yml

# Visual Studio Code
rpm --import https://packages.microsoft.com/keys/microsoft.asc
tee /etc/yum.repos.d/vscode.repo <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
sed -i "s/enabled=.*/enabled=0/g" /etc/yum.repos.d/vscode.repo
pdnf install --from-repo=code code

# QDiskInfo
copr_install_isolated "birkch/QDiskInfo" "QDiskInfo"

# kio-onedrive
copr_install_isolated "bernardogn/kio-onedrive" "kio-onedrive"

# Ookla Speedtest
rpm --import https://packagecloud.io/ookla/speedtest-cli/gpgkey
pdnf config-manager addrepo --from-repofile="https://packagecloud.io/install/repositories/ookla/speedtest-cli/config_file.repo?os=fedora&dist=36" --save-filename=ookla_speedtest_cli
sed -i "s/enabled=.*/enabled=0/g" /etc/yum.repos.d/ookla_speedtest_cli.repo
echo -e '%_pkgverify_level none\n%_pkgverify_flags 0x0' >> /root/.rpmmacros
pdnf install --nogpgcheck --from-repo=ookla_speedtest-cli speedtest
rm -f /root/.rpmmacros
