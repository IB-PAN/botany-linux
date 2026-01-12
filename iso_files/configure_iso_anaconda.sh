#!/usr/bin/env bash

set -eoux pipefail

IMAGE_INFO="$(cat /usr/share/ublue-os/image-info.json)"
#IMAGE_TAG="$(jq -c -r '."image-tag"' <<<"$IMAGE_INFO")"
#IMAGE_TAG="prod"
IMAGE_TAG="latest"
IMAGE_REF="$(jq -c -r '."image-ref"' <<<"$IMAGE_INFO")"
IMAGE_REF="${IMAGE_REF##*://}"

# Configure Live Environment
## Remove packages from liveCD to save space
dnf remove -y google-noto-fonts-all ublue-brew ublue-motd \
	onlyoffice-desktopeditors wine wine-core wine-mono 'mingw*' \
	libreoffice-core 'java-*' icedtea-web plasma-workspace-wallpapers \
	fluid-soundfont-gm Sunshine 'akonadi-server*' kmail \
	|| true

glib-compile-schemas /usr/share/glib-2.0/schemas

systemctl disable rpm-ostree-countme.service
systemctl disable tailscaled.service
systemctl disable bootloader-update.service
if [ -e "/usr/lib/systemd/system/brew-upgrade.timer" ]; then systemctl disable brew-upgrade.timer; fi
if [ -e "/usr/lib/systemd/system/brew-update.timer" ]; then systemctl disable brew-update.timer; fi
if [ -e "/usr/lib/systemd/system/brew-setup.timer" ]; then systemctl disable brew-setup.service; fi
systemctl disable rpm-ostreed-automatic.timer
systemctl disable uupd.timer
systemctl disable ublue-system-setup.service
systemctl disable ublue-guest-user.service
systemctl disable flatpak-preinstall.service
systemctl --global disable ublue-flatpak-manager.service
systemctl --global disable podman-auto-update.timer
systemctl --global disable ublue-user-setup.service
rm /usr/share/applications/system-update.desktop

systemctl disable swapspace.service
systemctl disable sshd.service
systemctl disable duperemove-weekly@$(systemd-escape /var/home).timer
systemctl disable xfs_scrub_all.timer
systemctl disable btrfs-scrub.timer
systemctl disable btrfs-balance.timer

# Configure Anaconda

# Install Anaconda WebUI
SPECS=(
	"libblockdev-btrfs"
	"libblockdev-lvm"
	"libblockdev-dm"
	"xfsprogs"
	"anaconda-live"
	"anaconda-webui"
	"firefox"
)
dnf install -y "${SPECS[@]}"

# Anaconda Profile Detection

# Aurora
tee /etc/anaconda/profile.d/botany-linux.conf <<'EOF'
# Anaconda configuration file for Aurora Stable

[Profile]
# Define the profile.
profile_id = botany-linux

[Profile Detection]
# Match os-release values
os_id = botany-linux

[Network]
default_on_boot = FIRST_WIRED_WITH_LINK

[Bootloader]
efi_dir = fedora
menu_auto_hide = True

[Storage]
default_scheme = BTRFS
btrfs_compression = zstd:1
default_partitioning =
	/     (min 1 GiB, max 70 GiB)
	/home (min 500 MiB, free 50 GiB)
	/var  (btrfs)

[User Interface]
custom_stylesheet = /usr/share/anaconda/pixmaps/fedora.css
hidden_spokes =
	PasswordSpoke
	UserSpoke
hidden_webui_pages =
	root-password
	anaconda-screen-accounts

[Localization]
use_geolocation = True
EOF

# Configure
. /etc/os-release
echo "Botany Linux release $VERSION_ID ($VERSION_CODENAME)" >/etc/system-release

sed -i 's/ANACONDA_PRODUCTVERSION=.*/ANACONDA_PRODUCTVERSION=""/' /usr/{,s}bin/liveinst || true
sed -i 's|^Icon=.*|Icon=/usr/share/anaconda/pixmaps/fedora-logo-icon.png|' /usr/share/applications/liveinst.desktop || true

# Get Artwork
git clone --depth=1 https://github.com/ublue-os/packages.git /root/packages
mkdir -p /usr/share/anaconda/pixmaps/
cp -r /root/packages/aurora/fedora-logos/src/anaconda/* /usr/share/anaconda/pixmaps/
rm -rf /root/packages

# Interactive Kickstart
tee -a /usr/share/anaconda/interactive-defaults.ks <<EOF
ostreecontainer --url=$IMAGE_REF:$IMAGE_TAG --transport=containers-storage --no-signature-verification
lang pl_PL.UTF-8
keyboard --vckeymap pl pl
timezone Europe/Warsaw
%include /usr/share/anaconda/post-scripts/install-configure-upgrade.ks
%include /usr/share/anaconda/post-scripts/disable-fedora-flatpak.ks
%include /usr/share/anaconda/post-scripts/install-flatpaks.ks
%include /usr/share/anaconda/post-scripts/secureboot-enroll-key.ks
%include /usr/share/anaconda/post-scripts/botany-configure.ks
%include /usr/share/anaconda/post-scripts/botany-configure-nochroot.ks
EOF

# Signed Images
tee /usr/share/anaconda/post-scripts/install-configure-upgrade.ks <<EOF
%post --erroronfail
bootc switch --mutate-in-place --enforce-container-sigpolicy --transport registry $IMAGE_REF:$IMAGE_TAG
%end
EOF

# Disable Fedora Flatpak
tee /usr/share/anaconda/post-scripts/disable-fedora-flatpak.ks <<'EOF'
%post --erroronfail
if [[ -e "/usr/lib/systemd/system/flatpak-add-fedora-repos.service" ]]; then
	systemctl mask flatpak-add-fedora-repos.service
fi
%end
EOF

# Install Flatpaks
tee /usr/share/anaconda/post-scripts/install-flatpaks.ks <<'EOF'
%post --erroronfail --nochroot
deployment="$(ostree rev-parse --repo=/mnt/sysimage/ostree/repo ostree/0/1/0)"
target="/mnt/sysimage/ostree/deploy/default/deploy/$deployment.0/var/lib/"
mkdir -p "$target"
rsync -aAXUHKP /var/lib/flatpak "$target"
%end
EOF

# Enroll Secureboot Key
tee /usr/share/anaconda/post-scripts/secureboot-enroll-key.ks <<'EOF'
%post --erroronfail --nochroot
set -oue pipefail

readonly ENROLLMENT_PASSWORD="botany"
readonly SECUREBOOT_KEY="/etc/pki/akmods/certs/botany.der"

if [[ ! -d "/sys/firmware/efi" ]]; then
	echo "EFI mode not detected. Skipping key enrollment."
	exit 0
fi

if [[ ! -f "$SECUREBOOT_KEY" ]]; then
	echo "Secure boot key not provided: $SECUREBOOT_KEY"
	exit 0
fi

SYS_ID="$(cat /sys/devices/virtual/dmi/id/product_name)"
if [[ ":Jupiter:Galileo:" =~ ":$SYS_ID:" ]]; then
	echo "Steam Deck hardware detected. Skipping key enrollment."
	exit 0
fi

mokutil --timeout -1 || :
echo -e "$ENROLLMENT_PASSWORD\n$ENROLLMENT_PASSWORD" | mokutil --import "$SECUREBOOT_KEY" || :
%end
EOF

tee /usr/share/anaconda/post-scripts/botany-configure.ks <<'EOF'
%post --erroronfail
useradd --comment "BOTANY_ADM" --password "" --groups wheel botany_adm
%end
EOF

tee /usr/share/anaconda/post-scripts/botany-configure-nochroot.ks <<'EOF'
%post --erroronfail --nochroot

deployment="$(ostree rev-parse --repo=/mnt/sysimage/ostree/repo ostree/0/1/0)"
target="/mnt/sysimage/ostree/deploy/default/deploy/$deployment.0"
hostname_file="$target/etc/hostname"
if [[ -f "$hostname_file" ]]; then
	hostname_numbers=$(grep -oE '[1-9]+$' "$hostname_file")
	if [[ -n "$hostname_numbers" ]]; then
		filesystem_type=$(stat -f -c %T "$target")
		target_mountpoint=$(stat --printf=%m "$target")
		if [[ "$filesystem_type" == "btrfs ]]; then
			btrfs filesystem label "$target_mountpoint" "botany_linux_$hostname_numbers" || true
		elif [[ "$filesystem_type" == "xfs ]]; then
			label=$(echo -n "botany$hostname_numbers" | cut -b1-12)
			xfs_io -c "label -s $label" "$target_mountpoint"
		fi
	fi
fi

%end
EOF