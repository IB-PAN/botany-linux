#!/usr/bin/bash

set -ouex pipefail

source /ctx/build_files/build-helpers.sh

APPS=(
    photocraft
    vectorcraft
    filmcraft
    lightcraft
    pdfcraft
    effectcraft
    designcraft
    figcraft
    wordcraft
    deckcraft
    gridcraft
    soundcraft
    cadcraft
    #bherbruck/solidcraft
)

declare -a APPS_RPM_URLS=()

for app in "${APPS[@]}"; do
    RPM_URL=$(curl --no-progress-meter --retry 3 "https://api.github.com/repos/storytold/$app/releases/latest" | jq -r '.assets[] | select(.content_type == "application/x-rpm") | select(.name | contains("x86_64")) | .browser_download_url')
    APPS_RPM_URLS+=("$RPM_URL")
done

pdnf_install_rpms "${APPS_RPM_URLS[@]}"
