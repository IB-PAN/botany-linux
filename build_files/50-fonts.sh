#!/usr/bin/bash

set -ouex pipefail

# MS fonts
#git clone --separate-git-dir=$(mktemp -u) --depth=1 https://github.com/pjobson/Microsoft-365-Fonts.git /usr/share/fonts/Microsoft-365-Fonts && rm -rf /usr/share/fonts/Microsoft-365-Fonts/.git/* /usr/share/fonts/Microsoft-365-Fonts/.git
curl --no-progress-meter --retry 3 -Lo  /tmp/Microsoft-365-Fonts.zip https://github.com/pjobson/Microsoft-365-Fonts/archive/refs/heads/main.zip
7z x -o/usr/share/fonts/ /tmp/Microsoft-365-Fonts.zip
mv /usr/share/fonts/{Microsoft-365-Fonts-main,Microsoft-365-Fonts}
rm /tmp/Microsoft-365-Fonts.zip
chown -R root:root /usr/share/fonts/Microsoft-365-Fonts
chmod -R 644 /usr/share/fonts/Microsoft-365-Fonts
chmod -R a+X /usr/share/fonts/Microsoft-365-Fonts

# FiraCode Nerd Font
curl --no-progress-meter --retry 3 -Lo  /tmp/FiraCodeNerdFont.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraCode.zip
mkdir -p /usr/share/fonts/nerd-fonts/FiraCodeNerdFont/
7z x -o/usr/share/fonts/nerd-fonts/FiraCodeNerdFont/ /tmp/FiraCodeNerdFont.zip
rm /tmp/FiraCodeNerdFont.zip
chown -R root:root /usr/share/fonts/nerd-fonts/
chmod -R 644 /usr/share/fonts/nerd-fonts/
chmod -R a+X /usr/share/fonts/nerd-fonts/

fc-cache -f -v
