#!/bin/bash

source /usr/lib/ublue/setup-services/libsetup.sh

version-script botany-bees system 1 || exit 0

set -x

# adapted from:
# https://github.com/ublue-os/bazzite/blob/main/system_files/desktop/shared/usr/share/ublue-os/just/82-bazzite-beesd.just

# Constants for bees hash table sizing
readonly MIN_FS_TB=1
readonly MAX_FS_TB=4
readonly HASH_SIZE_MB_PER_TB=512

remove_beesd_config() {
	local uuid="$1"
	echo "Removing configuration..."
	sudo systemctl disable --now "beesd@${uuid}.timer"
	sudo systemctl stop "beesd@${uuid}.service" 2>/dev/null || true
	sudo rm "/etc/bees/${uuid}.conf"
	sudo rm -f "/etc/systemd/system/beesd@${uuid}.service.d/override.conf"
	sudo rmdir "/etc/systemd/system/beesd@${uuid}.service.d" 2>/dev/null || true
	echo "Configuration removed and timer disabled."

	echo "Cleaning leftover data"
	fs_root=$(findmnt --source UUID="$uuid" -o TARGET,OPTIONS | grep "subvolid=5" | awk '{print $1}')
	is_manual_mount=false
	if [[ -z "$fs_root" ]]; then
		fs_root="/run/bees/mnt/${uuid}"
		sudo mkdir -p "$fs_root"
		if ! sudo mount -o subvolid=5 UUID="$uuid" "$fs_root"; then
			fs_root=""
		else
			is_manual_mount=true
		fi
	fi

	if [[ -n "$fs_root" ]]; then
		beeshome_id=$(sudo btrfs subvolume list "$fs_root" -t | grep "\.beeshome" | awk '{print $1}')
		if [[ -n "$beeshome_id" ]]; then
			echo "Found .beeshome subvolume with ID: $beeshome_id"
			sudo btrfs subvolume delete -i "$beeshome_id" "$fs_root"
			echo "Deleted .beeshome subvolume"
		else
			echo "No .beeshome subvolume found"
		fi

		if [[ "$is_manual_mount" == true ]]; then
			sudo umount "$fs_root"
			sleep 1
			# Device might still be busy
			# Not critical if this fails
			sudo rmdir "$fs_root" >/dev/null 2>&1
		fi
	fi

	sudo systemctl daemon-reload
}

readonly UUID_SYSROOT="$(findmnt -e -v -n -o UUID --target /sysroot)"

# Get btrfs filesystem info
mapfile -t raw_btrfs_output < <(lsblk --fs --list --noheadings --output "NAME,UUID,SIZE" --filter 'FSTYPE == "btrfs"' --bytes)

if [[ ${#raw_btrfs_output[@]} -eq 0 ]]; then
	echo "No BTRFS filesystems found."
	exit 0
fi

# Check for existing configurations
unset configured_uuids
declare -A configured_uuids
if [[ -d "/etc/bees" ]]; then
	for config in /etc/bees/*.conf; do
		if [[ -f "$config" ]]; then
			filename=$(basename "$config" .conf)
			configured_uuids["$filename"]=1
		fi
	done
fi

# Create menu options and size map
menu_options=()
unset filesystem_size_map
declare -A filesystem_size_map
for line in "${raw_btrfs_output[@]}"; do
	read -r name uuid size_bytes <<< "$line"
	# Convert bytes to human readable for display
	size_human=$(numfmt --to=iec-i --suffix=B "$size_bytes")
	filesystem_size_map["$uuid"]="$size_bytes"

	if ! [[ -n "${configured_uuids[$uuid]}" ]]; then
		if [[ "$uuid" == "$UUID_SYSROOT" ]]; then # /sysroot
			size_tb=$((size_bytes / 1024**4))
			# Clamp filesystem size between min/max for hash table calculation
			# Avoid eating too much memory when bees starts
			size_tb=$(($size_tb < $MIN_FS_TB ? $MIN_FS_TB : $size_tb))
			size_tb=$(($size_tb > $MAX_FS_TB ? $MAX_FS_TB : $size_tb))
			# Bees Hash Table Sizing
			# Size MUST be multiple of 128KB
			# DB_SIZE=$((1024*1024*1024)) # 1G in bytes
			db_size=$((size_tb * $HASH_SIZE_MB_PER_TB * 1024**2))
			# Convert db_size from bytes to MB for memory threshold
			mem_thresh_mb=$((db_size / 1024**2))

			mkdir -p /etc/bees
			cp /usr/etc/bees/beesd.conf.sample "/etc/bees/${uuid}.conf"
			# https://github.com/Zygo/bees/blob/master/docs/options.md#load-management-options
			sed -i "s/^UUID=.*/UUID=${uuid}/" "/etc/bees/${uuid}.conf"
			sed -i "s/# DB_SIZE=.*/DB_SIZE=${db_size}/" "/etc/bees/${uuid}.conf"
			echo "Created /etc/bees/${uuid}.conf with DB_SIZE=$((db_size / 1024**2)) MB"

			# Only start the service if enough memory is free
			# Per service as hash table size may differ in each configuration
			mkdir -p "/etc/systemd/system/beesd@${uuid}.service.d"
			{
				echo "[Service]"
				echo "ExecCondition=/bin/sh -c \"test \$(free -m | awk '/^Mem:/ {print \$7}') -gt ${mem_thresh_mb}\""
			} | tee "/etc/systemd/system/beesd@${uuid}.service.d/override.conf" > /dev/null

			systemctl daemon-reload
			systemctl enable --now "beesd@${uuid}.timer"
		fi
	fi
done
