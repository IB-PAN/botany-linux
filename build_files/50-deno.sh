#!/usr/bin/bash

set -ouex pipefail

# deno
curl --no-progress-meter --retry 3 -Lo /tmp/deno.zip https://github.com/denoland/deno/releases/latest/download/deno-x86_64-unknown-linux-gnu.zip
7z x -o/tmp/ /tmp/deno.zip
rm /tmp/deno.zip
install -Dm755 "/tmp/deno" "/usr/bin/deno"
rm /tmp/deno
