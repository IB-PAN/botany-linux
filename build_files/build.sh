#!/bin/bash

set -ouex pipefail

echo "{\"auths\":{\"${IMAGE_REGISTRY}\":{\"auth\":\"`echo -n "${REGISTRY_PULLER_USER}:${REGISTRY_PULLER_PASSWORD}" | base64`\"}}}" | tee /usr/lib/ostree/auth.json

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y screen gparted signon-kwallet-extension signon-ui

dnf5 remove -y kde-connect kde-connect-libs kde-connect-nautilus

# aurora-kde-config aurora-plymouth aurora-backgrounds aurora-cli-logos aurora-fastfetch kcm_ublue
dnf5 remove -y aurora-plymouth aurora-backgrounds aurora-kde-config

dnf5 install -y libreoffice libreoffice-help-pl libreoffice-langpack-pl

mkdir -p /usr/opt/onlyoffice
ln -s /opt/onlyoffice /usr/opt/onlyoffice
wget -nc -nv -O /tmp/onlyoffice-desktopeditors.x86_64.rpm https://github.com/ONLYOFFICE/DesktopEditors/releases/latest/download/onlyoffice-desktopeditors.x86_64.rpm
rpm -i --relocate /opt=/usr/opt --badreloc /tmp/onlyoffice-desktopeditors.x86_64.rpm
rm /tmp/onlyoffice-desktopeditors.x86_64.rpm

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket

# bun
wget -nc -nv -O /tmp/bun.zip https://github.com/oven-sh/bun/releases/latest/download/bun-linux-x64-baseline.zip
7z x -si -o/tmp /tmp/bun.zip
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

# Branding test
#dnf5 -y swap aurora-logos fedora-logos
# Problem: installed package aurora-kde-config-0.1.1-1.fc42.noarch requires aurora-logos, but none of the providers can be installed
bun /ctx/branding.js

# MS fonts
#git clone --separate-git-dir=$(mktemp -u) --depth=1 https://github.com/pjobson/Microsoft-365-Fonts.git /usr/share/fonts/Microsoft-365-Fonts && rm -rf /usr/share/fonts/Microsoft-365-Fonts/.git/* /usr/share/fonts/Microsoft-365-Fonts/.git
wget -nc -nv -O /tmp/Microsoft-365-Fonts.zip https://github.com/pjobson/Microsoft-365-Fonts/archive/refs/heads/main.zip
7z x -si -o/usr/share/fonts/ /tmp/Microsoft-365-Fonts.zip
mv /usr/share/fonts/{Microsoft-365-Fonts-main,Microsoft-365-Fonts}
rm /tmp/Microsoft-365-Fonts.zip
fc-cache -f -v

/ctx/fix_kde_google_integration.sh
