#!/usr/bin/bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script botany-misc privileged 1 || exit 0

set -x

# allow Samba usershares for this user
usermod -aG usershares "$user"
