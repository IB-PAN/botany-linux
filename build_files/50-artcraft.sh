#!/usr/bin/bash

set -ouex pipefail

source /ctx/build_files/build-helpers.sh

APPS=(
    storytold/photocraft
    storytold/vectorcraft
    storytold/filmcraft
    storytold/lightcraft
    storytold/pdfcraft
    storytold/effectcraft
    storytold/designcraft
    storytold/figcraft
    storytold/wordcraft
    storytold/deckcraft
    storytold/gridcraft
    storytold/soundcraft
    storytold/cadcraft
    #tangency-labs/solidcraft
)

declare -a APPS_RPM_URLS=()

for repo in "${APPS[@]}"; do
    app=${repo##*/}
    if ! RPM_URL=$(curl --no-progress-meter --retry 3 --fail "https://api.github.com/repos/$repo/releases/latest" | jq -r '[.assets[] | select(.content_type == "application/x-rpm") | select(.name | contains("x86_64")) | .browser_download_url] | first // empty'); then
        echo "[$app] failed to query latest release" >&2
        exit 1
    fi
    if [[ -z $RPM_URL ]]; then
        echo "[$app] no x86_64 RPM found in latest release" >&2
        exit 1
    fi
    APPS_RPM_URLS+=("$RPM_URL")
done

pdnf_install_rpms "${APPS_RPM_URLS[@]}"
