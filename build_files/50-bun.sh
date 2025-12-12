#!/usr/bin/bash

set -ouex pipefail

# bun
curl --no-progress-meter --retry 3 -Lo /tmp/bun.zip https://github.com/oven-sh/bun/releases/latest/download/bun-linux-x64-baseline.zip
7z x -o/tmp/ /tmp/bun.zip
rm /tmp/bun.zip
pushd /tmp/bun-linux-*
install -dm755 "completions"
SHELL=zsh "./bun" completions >"completions/bun.zsh"
SHELL=bash "./bun" completions >"completions/bun.bash"
SHELL=fish "./bun" completions >"completions/bun.fish"
install -Dm755 "./bun" "/usr/bin/bun"
ln -s bun "/usr/bin/bunx"
install -Dm644 completions/bun.zsh "/usr/share/zsh/site-functions/_bun"
install -Dm644 completions/bun.bash "/usr/share/bash-completion/completions/bun"
install -Dm644 completions/bun.fish "/usr/share/fish/vendor_completions.d/bun.fish"
popd
rm -rf /tmp/bun-linux-*

# Branding
bun /ctx/build_files/branding.js
