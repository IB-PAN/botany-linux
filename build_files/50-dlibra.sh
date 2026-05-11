#!/usr/bin/bash

set -ouex pipefail

source /ctx/build_files/build-helpers.sh

# icedtea-web is locked to java-21-openjdk, while Fedora repos only have java-25-openjdk
# https://fedoraproject.org/wiki/Changes/Java21RemovedEarlierThenScheduled
# https://docs.fedoraproject.org/en-US/quick-docs/installing-java/#_installing_an_older_java_version
# https://discussion.fedoraproject.org/t/cannot-install-icedtea-web/190186
# https://discussion.fedoraproject.org/t/icedtea-available-for-42/148857/10
pdnf install adoptium-temurin-java-repository --allowerasing
pdnf config-manager setopt adoptium-temurin-java-repository.enabled=1

# dLibra
curl --no-progress-meter --retry 3 -Lo /usr/share/icons/dlibra-soft-icon.png https://rcin.org.pl/jnlp2/softIcon.png
pdnf install icedtea-web
