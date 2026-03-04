#!/usr/bin/bash

set -ouex pipefail

source /ctx/build_files/build-helpers.sh

pdnf install R

# RStudio Desktop
copr_install_isolated "iucar/rstudio" "rstudio-desktop" "rstudio-server"

# Fix missing icon
jq --arg desktopName "rstudio.desktop" '.["desktopName"] = ($desktopName)' /usr/libexec/rstudio/package.json | sponge /usr/libexec/rstudio/package.json

# Extra CRAN packages using cran2copr repo
pdnf copr enable "iucar/cran"
pdnf copr disable "iucar/cran"
mkdir -p /tmp/crans
pdnf download --resolve --destdir=/tmp/crans --from-repo="copr:copr.fedorainfracloud.org:iucar:cran" \
    R-CRAN-languageserver \
    R-CRAN-rmarkdown R-CRAN-rgbif R-CRAN-spocc R-CRAN-maps R-CRAN-mapproj R-CRAN-mapdata R-CRAN-dismo R-CRAN-raster R-CRAN-plotly \
    R-CRAN-RColorBrewer R-CRAN-tidyverse R-CRAN-readxl R-CRAN-leafpop R-CRAN-geodata \
    R-CRAN-sf R-CRAN-ggplot2 R-CRAN-ggmap R-CRAN-CoordinateCleaner \
    R-CRAN-sdm R-CRAN-enmSdmX R-CRAN-ENMTools R-CRAN-gam R-CRAN-spatstat R-CRAN-ppmlasso \
    R-CRAN-SSDM R-CRAN-Hmsc R-CRAN-boral R-CRAN-jSDM R-CRAN-phytools R-CRAN-ape R-CRAN-geiger
find /tmp/crans -name '*.src.rpm' -type f -delete
prpm --install --replacefiles --badreloc --relocate /usr/local/lib/R/library/=/usr/lib64/R/library/ /tmp/crans/*.rpm
rm -rf /tmp/crans

#copr_install_isolated "@copr/PyPI" "python-radian"
