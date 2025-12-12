#!/usr/bin/bash

set -ouex pipefail

# dLibra
curl --no-progress-meter --retry 3 -Lo /usr/share/icons/dlibra-soft-icon.png https://rcin.org.pl/jnlp2/softIcon.png
dnf5 install -y icedtea-web
