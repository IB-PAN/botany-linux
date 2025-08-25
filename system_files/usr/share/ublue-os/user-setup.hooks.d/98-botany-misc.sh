#!/usr/bin/bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script botany-misc user 1 || exit 0

set -x

# Remove Aurora prompt where it was already dropped, we use our global config at /usr/share/botany/starship.toml instead
if [[ -f "$HOME"/.config/starship.toml && "$(md5sum "$HOME"/.config/starship.toml | awk '{print $1}')" == "b7a2078973f13d2198498053b0ff5043" ]]; then
	rm -f "$HOME"/.config/starship.toml
fi
