#!/usr/bin/bash

set -ouex pipefail

source /ctx/build_files/build-helpers.sh

pdnf install pacman

#DBPath      = /var/lib/pacman/
#CacheDir    = /var/cache/pacman/pkg/
#LogFile     = /var/log/pacman.log
#GPGDir      = /etc/pacman.d/gnupg/
#HookDir     = /etc/pacman.d/hooks/

sed -i -E 's!^#?RootDir\s*=.*$!RootDir = /tmp/pacmanroot/!g' /etc/pacman.conf
sed -i -E 's!^#?CacheDir\s*=.*$!CacheDir = /tmp/pacmanroot/var/cache/pacman/pkg/!g' /etc/pacman.conf
sed -i -E 's!^#?LogFile\s*=.*$!LogFile = /tmp/pacmanroot/var/log/pacman.log!g' /etc/pacman.conf
sed -i -E 's!^#?GPGDir\s*=.*$!GPGDir = /tmp/pacmanroot/etc/pacman.d/gnupg/!g' /etc/pacman.conf
sed -i -E 's!^#?HookDir\s*=.*$!HookDir = /tmp/pacmanroot/etc/pacman.d/hooks/!g' /etc/pacman.conf

sed -i '1s|^|Server = https://ftp.icm.edu.pl/pub/Linux/dist/archlinux/$repo/os/$arch\n|' /etc/pacman.d/mirrorlist
sed -i '1s|^|Server = https://ftp.psnc.pl/linux/archlinux/$repo/os/$arch\n|' /etc/pacman.d/mirrorlist
echo 'Server = https://archive.archlinux.org/.all' >> /etc/pacman.d/mirrorlist

mkdir -p /tmp/pacmanroot
mkdir -p /tmp/pacmanroot/var/{cache,lib}/pacman /tmp/pacmanroot/{etc/pacman.d,log}
rsync -arv /etc/pacman.d/ /tmp/pacmanroot/pacman.d/

# Populate pacman keys using existing files at /usr/share/pacman/keyrings initially (from Fedora's archlinux-keyring package),
# so that we can download any packages
pacman-key --init
pacman-key --populate

# Switch over the keyring folders to a symlink to pacman-managed one
mkdir -p /tmp/pacmanroot/usr/share/pacman/keyrings
mv /usr/share/pacman/{keyrings,keyrings_original}
ln -s /tmp/pacmanroot/usr/share/pacman/keyrings /usr/share/pacman/keyrings

# Now install the keyring from Arch repos
pacman -Sydd --noconfirm archlinux-keyring

# BioArchLinux
pacman-key --recv-keys B1F96021DB62254D
pacman-key --finger B1F96021DB62254D
pacman-key --lsign-key B1F96021DB62254D
tee -a /etc/pacman.conf <<'EOF'
[bioarchlinux]
Server = https://repo.bioarchlinux.org/$arch
EOF

# Chaotic AUR
pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
pacman-key --lsign-key 3056513887B78AEB
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
tee -a /etc/pacman.conf <<'EOF'
[chaotic-aur]
Server = https://cdn-mirror.chaotic.cx/$repo/$arch
Include = /tmp/pacmanroot/etc/pacman.d/chaotic-mirrorlist
EOF

# Arch4Edu
pacman-key --recv-keys 7931B6D628C8D3BA
pacman-key --finger 7931B6D628C8D3BA
pacman-key --lsign-key 7931B6D628C8D3BA
curl --retry 3 -sSLo /tmp/pacmanroot/etc/pacman.d/mirrorlist.arch4edu https://raw.githubusercontent.com/arch4edu/mirrorlist/refs/heads/master/mirrorlist.arch4edu
tee -a /etc/pacman.conf <<'EOF'
[arch4edu]
Include = /tmp/pacmanroot/etc/pacman.d/mirrorlist.arch4edu
EOF

pacman-key --populate
pacman -Sydd --noconfirm bioarchlinux-keyring chaotic-keyring arch4edu-keyring
pacman -Sudd --noconfirm chaotic-mirrorlist mirrorlist.arch4edu
pacman-key --populate

# pdf-xchange (Chaotic AUR)
pacman -Swdd --noconfirm pdf-xchange
tar --overwrite -xavf /tmp/pacmanroot/var/cache/pacman/pkg/pdf-xchange-*.pkg.tar.zst --directory=/ usr

# Restore original keyrings folder (instead of the symlink)
rm -f /usr/share/pacman/keyrings
mv /usr/share/pacman/{keyrings_original,keyrings}

# Cleanup
pacman -Scc --noconfirm
pdnf remove pacman libalpm pacman-filesystem archlinux-keyring
rm -rf /etc/pacman.{conf,d}
rm -rf /var/{cache,lib}/pacman /var/log/pacman.log /root/.cache/paru
rm -rf /tmp/pacmanroot
