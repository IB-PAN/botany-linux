#!/usr/bin/bash

set -ouex pipefail

source /ctx/build_files/build-helpers.sh

# Office suites (OnlyOffice)
pdnf_install_rpm https://github.com/ONLYOFFICE/DesktopEditors/releases/latest/download/onlyoffice-desktopeditors.x86_64.rpm
