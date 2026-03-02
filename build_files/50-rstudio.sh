#!/usr/bin/bash

set -ouex pipefail

source /ctx/build_files/build-helpers.sh

# RStudio Desktop
gpg --yes --keyserver keys.openpgp.org --recv 51C0B5BB19F92D60
rpm --import <(gpg --export --armor 51C0B5BB19F92D60)

pdnf_install_rpm_checksig https://rstudio.org/download/latest/stable/desktop/fedora43/rstudio-latest-x86_64.rpm
