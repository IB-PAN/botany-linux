#!/usr/bin/bash

set -ouex pipefail

source /ctx/build_files/build-helpers.sh

# OpenRefine
OPENREFINE_TAR_GZ_URL="$(curl --no-progress-meter --retry 3 https://api.github.com/repos/OpenRefine/OpenRefine/releases/latest | awk '/openrefine-linux-.*.tar.gz/&&/browser_download_url/{ gsub(/"/, "", $2); print $2 }')"
curl --no-progress-meter --retry 3 -Lo /tmp/openrefine.tar.gz "$OPENREFINE_TAR_GZ_URL"
mkdir -p /opt/openrefine
tar -xaf /tmp/openrefine.tar.gz -C /opt/openrefine --strip-components=1
rm -f /tmp/openrefine.tar.gz

mkdir -p /usr/share/licenses/openrefine
cp /opt/openrefine/LICENSE.txt /usr/share/licenses/openrefine/
cp /opt/openrefine/licenses.xml /usr/share/licenses/openrefine/
cp -r /opt/openrefine/licenses /usr/share/licenses/openrefine/

curl --no-progress-meter --retry 3 -Lo /usr/share/icons/hicolor/scalable/apps/openrefine.svg https://openrefine.org/img/openrefine_logo.svg
tee /usr/share/applications/openrefine.desktop <<EOF
[Desktop Entry]
Version=1.0
Name=OpenRefine
Comment=Power tool for working with messy data and improving it
Categories=Utility;
Exec=/opt/openrefine/refine
Terminal=true
Type=Application
Icon=openrefine
StartupNotify=false
EOF
