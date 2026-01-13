#!/usr/bin/bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script botany-misc user 3 || exit 0

set -x

# Remove Aurora prompt where it was already dropped, we use our global config at /usr/share/botany/starship.toml instead
if [[ -f "$HOME"/.config/starship.toml && "$(md5sum "$HOME"/.config/starship.toml | awk '{print $1}')" == "b7a2078973f13d2198498053b0ff5043" ]]; then
	rm -f "$HOME"/.config/starship.toml
fi

if [[ ! -f "$HOME"/.var/app/org.gnome.Crosswords/config/glib-2.0/settings/keyfile ]]; then
	mkdir -p "$HOME"/.var/app/org.gnome.Crosswords/config/glib-2.0/settings/
	echo -e "[org/gnome/Crosswords]\nshown-puzzle-sets=['technopol-daily']" > "$HOME"/.var/app/org.gnome.Crosswords/config/glib-2.0/settings/keyfile
fi

if [[ ! -f "$HOME"/.var/app/com.ranfdev.DistroShelf/config/glib-2.0/settings/keyfile ]]; then
	mkdir -p "$HOME"/.var/app/com.ranfdev.DistroShelf/config/glib-2.0/settings/
	echo -e "[com/ranfdev/DistroShelf]\nselected-terminal='Konsole'" > "$HOME"/.var/app/com.ranfdev.DistroShelf/config/glib-2.0/settings/keyfile
fi
if [[ ! -e "$HOME"/.docker/config.json ]]; then
	ln -s /usr/lib/ostree/auth.json "$HOME"/.docker/config.json
fi
