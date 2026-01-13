#!/usr/bin/bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script botany-authselect system 1 || exit 0

set -x

# An update happened to leave the outdated config in /etc, so let's re-generate it on the host if needed
# (we are interested in enabling pam-u2f)
authselect select --force --nobackup local \
    with-silent-lastlog \
    with-mdns4 \
    with-fingerprint \
    with-pam-u2f
authselect apply-changes
