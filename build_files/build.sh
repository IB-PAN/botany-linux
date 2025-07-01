#!/bin/bash

set -ouex pipefail

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/39/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
dnf5 install -y tmux 

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket

# Branding test
#dnf5 -y swap aurora-logos fedora-logos
# Problem: installed package aurora-kde-config-0.1.1-1.fc42.noarch requires aurora-logos, but none of the providers can be installed
sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"Botany Linux 42\"|" /usr/lib/os-release
sed -i "s|^NAME=.*|NAME=\"Botany Linux\"|" /usr/lib/os-release
sed -i "s|^HOME_URL=.*|HOME_URL=\"https://botany.pl\"|" /usr/lib/os-release
sed -i "s|^LOGO=.*|LOGO=\"ibpan-logo\"|" /usr/lib/os-release
