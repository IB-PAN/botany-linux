#!/bin/bash

set -ouex pipefail

# It's just an icon, but apparently it could take 5 seconds to download...
curl --no-progress-meter --retry 3 -Lo /usr/share/icons/teamviewer-dl.svg https://upload.wikimedia.org/wikipedia/commons/3/31/TeamViewer_Logo_Icon_Only.svg
