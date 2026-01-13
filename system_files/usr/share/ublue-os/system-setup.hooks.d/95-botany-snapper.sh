#!/usr/bin/bash

source /usr/lib/ublue/setup-services/libsetup.sh

# Run only on btrfs
[[ "$(stat -f -c %T /var/home)" == "btrfs" ]] || exit 0

version-script botany-snapper system 1 || exit 0

set -x

set_snapper_defaults() {
	snapper set-config "TIMELINE_CLEANUP=yes"
	snapper set-config "TIMELINE_MIN_AGE=1800"
	snapper set-config "TIMELINE_LIMIT_DAILY=1-10"
	snapper set-config "TIMELINE_LIMIT_HOURLY=1-36"
	snapper set-config "TIMELINE_LIMIT_MONTHLY=0"
	snapper set-config "TIMELINE_LIMIT_WEEKLY=0"
	snapper set-config "TIMELINE_LIMIT_QUARTERLY=0"
	snapper set-config "TIMELINE_LIMIT_YEARLY=0"

	snapper set-config "NUMBER_CLEANUP=no"
	snapper set-config "NUMBER_MIN_AGE=1800"
	snapper set-config "NUMBER_LIMIT=0"
	snapper set-config "NUMBER_LIMIT_IMPORTANT=0"
}

if ! snapper get-config >/dev/null 2>&1; then
	# Make a config for /var/home as /home will not work
	snapper create-config /var/home

	# Set the snapper config settings
	set_snapper_defaults

	# Set timers
	systemctl disable --now snapper-boot.timer
	systemctl enable --now snapper-timeline.timer
	systemctl enable --now snapper-cleanup.timer

	snapper setup-quota || true
fi
