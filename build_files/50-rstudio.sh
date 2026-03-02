#!/usr/bin/bash

set -ouex pipefail

source /ctx/build_files/build-helpers.sh

# RStudio Desktop
copr_install_isolated "iucar/rstudio" "rstudio-desktop" "rstudio-server"

# Fix missing icon
jq --arg desktopName "rstudio.desktop" '.["desktopName"] = ($desktopName)' /usr/libexec/rstudio/package.json | sponge /usr/libexec/rstudio/package.json

# Extra CRAN packages using cran2copr repo
pdnf copr enable "iucar/cran"
mkdir -p /tmp/crans
pdnf download --resolve --destdir=/tmp/crans --from-repo="copr:copr.fedorainfracloud.org:iucar:cran" \
    "R-CRAN-languageserver" \
    "R-CRAN-rmarkdown" "R-CRAN-rgbif" "R-CRAN-spocc" "R-CRAN-maps" "R-CRAN-mapproj" "R-CRAN-mapdata" "R-CRAN-dismo" "R-CRAN-raster" "R-CRAN-plotly" \
    "R-CRAN-RColorBrewer" "R-CRAN-tidyverse" "R-CRAN-readxl" "R-CRAN-leafpop" "R-CRAN-geodata"
find /tmp/crans -name '*.src.rpm' -type f -delete
rpm --install --replacefiles --badreloc --relocate /usr/local/lib/R/library/=/usr/lib64/R/library/ /tmp/crans/*.rpm
pdnf copr disable "iucar/cran"
rm -rf /tmp/crans

#copr_install_isolated "@copr/PyPI" "python-radian"
