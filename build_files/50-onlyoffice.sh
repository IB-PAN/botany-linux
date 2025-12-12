#!/usr/bin/bash

set -ouex pipefail

# Office suites (OnlyOffice)
curl --no-progress-meter --retry 3 -Lo /tmp/onlyoffice-desktopeditors.x86_64.rpm https://github.com/ONLYOFFICE/DesktopEditors/releases/latest/download/onlyoffice-desktopeditors.x86_64.rpm
dnf5 install -y --nogpgcheck /tmp/onlyoffice-desktopeditors.x86_64.rpm
rm /tmp/onlyoffice-desktopeditors.x86_64.rpm
