#!/usr/bin/bash

set -ouex pipefail

source /ctx/build_files/build-helpers.sh

# RStudio Desktop
copr_install_isolated "iucar/rstudio" "rstudio-desktop" "rstudio-server"

# Fix missing icon
jq --arg desktopName "rstudio.desktop" '.["desktopName"] = ($desktopName)' /usr/libexec/rstudio/package.json | sponge /usr/libexec/rstudio/package.json

# Extra CRAN packages using cran2copr repo
# - languageserver is needed for VS Code extension
#copr_install_isolated "iucar/cran" "R-CRAN-languageserver" \
#    "R-CRAN-rmarkdown" "R-CRAN-rgbif" "R-CRAN-spocc" "R-CRAN-maps" "R-CRAN-mapproj" "R-CRAN-mapdata" "R-CRAN-dismo" "R-CRAN-raster" "R-CRAN-plotly" \
#    "R-CRAN-RColorBrewer" "R-CRAN-tidyverse" "R-CRAN-readxl"

# R-CRAN packages install to wrong dir...
#rsync -avh --remove-source-files /usr/local/lib/R/library/ /usr/lib64/R/library/

#copr_install_isolated "@copr/PyPI" "python-radian"
