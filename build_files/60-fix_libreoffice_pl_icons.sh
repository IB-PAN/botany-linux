#!/bin/bash

set -ouex pipefail

echo "Fixing LibreOffice localized icons..."

FILES="/usr/lib64/libreoffice/share/config/images_*.zip"
for f in $FILES
do
    echo "Processing $f file..."
    7z d -r "$f" cmd/pl cmd/32/pl >/dev/null

    # "Note: The current version of 7-Zip support reading of archives from stdin only for xz, lzma, tar, gzip and bzip2 archives."
    #LIBREOFFICE_IMAGES_LINK_TXT_CONTENTS=$(7z x -so "$f" links.txt | grep -Fv 'cmd/32/pl/' | grep -Fv 'cmd/pl/')
    #echo $LIBREOFFICE_IMAGES_LINK_TXT_CONTENTS
    #7z u "$f" -silinks.txt <<< "$LIBREOFFICE_IMAGES_LINK_TXT_CONTENTS"

    7z x -so "$f" links.txt | grep -Fv 'cmd/32/pl/' | grep -Fv 'cmd/pl/' > /tmp/links.txt
    7z u "$f" /tmp/links.txt >/dev/null
    rm /tmp/links.txt
done
