#!/usr/bin/bash

source /usr/lib/ublue/setup-services/libsetup.sh

distrobox_app_cache_dir=${XDG_CACHE_HOME:-"${HOME}/.cache"}/distrobox
mkdir -p "$distrobox_app_cache_dir"
distrobox_app_cache_ls_checksum=$(find "$distrobox_app_cache_dir" -name 'distrobox-compatibility-*' | md5sum | awk '{print $1}')
distrobox_version=$(distrobox --version | awk '{print $2}')

version-script botany-distrobox user 1-$distrobox_version-$distrobox_app_cache_ls_checksum || exit 0

set -x

if [[ ! -f "$HOME"/.var/app/com.ranfdev.DistroShelf/config/glib-2.0/settings/keyfile ]]; then
	mkdir -p "$HOME"/.var/app/com.ranfdev.DistroShelf/config/glib-2.0/settings/
	echo -e "[com/ranfdev/DistroShelf]\nselected-terminal='Konsole'" > "$HOME"/.var/app/com.ranfdev.DistroShelf/config/glib-2.0/settings/keyfile
fi

#if [[ ! -e "$HOME"/.docker/config.json ]]; then
#	ln -s /usr/lib/ostree/auth.json "$HOME"/.docker/config.json
#fi

# Populate the distrobox compatibility file (the list of default images) (separate file for every distrobox version)
find "$distrobox_app_cache_dir" -name 'distrobox-compatibility-*' -delete
distrobox-create --compatibility >/dev/null

# Add our Distrobox images to the list of default supported images (to be shown in apps like Distroshelf)
IMAGES_TO_ADD=(
	ghcr.io/ib-pan/arch-linux-distrobox:latest
)
for filename in "$distrobox_app_cache_dir"/distrobox-compatibility-*; do
	for image_to_add in "${IMAGES_TO_ADD[@]}"; do
		if ! grep -qFx "$image_to_add" "$filename"; then
			#echo "$image_to_add" >> "$filename"
			# Prepend
			sed -i "1s|^|$image_to_add\n|" "$filename"
		fi
	done
done
