#!/usr/bin/bash

set -ouex pipefail

source /ctx/build_files/build-helpers.sh

# Ookla Speedtest
curl --no-progress-meter --retry 3 -Lo /tmp/ookla-speedtest.tgz "https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-$(arch).tgz"
tar -xaf /tmp/ookla-speedtest.tar.gz -C /usr/bin speedtest
tar -xaf /tmp/ookla-speedtest.tar.gz -C /usr/share/man/man5 speedtest.5
mkdir -p /usr/share/doc/speedtest
tar -xaf /tmp/ookla-speedtest.tar.gz -C /usr/share/doc/speedtest speedtest.md
rm -f /tmp/ookla-speedtest.tgz
