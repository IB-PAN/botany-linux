#!/usr/bin/bash

set -ouex pipefail

source /ctx/build_files/build-helpers.sh

# dLibra
curl --no-progress-meter --retry 3 -Lo /usr/share/icons/dlibra-soft-icon.png https://rcin.org.pl/jnlp2/softIcon.png
pdnf install icedtea-web
