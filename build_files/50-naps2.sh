#!/usr/bin/bash

set -ouex pipefail

source /ctx/build_files/build-helpers.sh

# NAPS2
NAPS2_RPM_URL="$(curl --no-progress-meter --retry 3 https://api.github.com/repos/cyanfish/naps2/releases/latest | awk '/naps2-.*-linux-x64.rpm/&&/browser_download_url/{ gsub(/"/, "", $2); print $2 }')"
pdnf_install_rpm "$NAPS2_RPM_URL"
xmlstarlet edit --inplace --update "/AppConfig/HideDonateButton" --value "true" /usr/lib/naps2/appsettings.xml 2>/dev/null
xmlstarlet edit --inplace --update "/AppConfig/NoUpdatePrompt" --value "true" /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --update "/AppConfig/ShowPageNumbers[@mode='default']" --value "true" /usr/lib/naps2/appsettings.xml 2>/dev/null
xmlstarlet edit --inplace --update "/AppConfig/DefaultProfileSettings/Resolution" --value "Dpi300" /usr/lib/naps2/appsettings.xml 2>/dev/null
xmlstarlet edit --inplace --update "/AppConfig/DefaultProfileSettings/PageSize" --value "A4" /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig" --type elem --name "ImageSettings" /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig/ImageSettings" --type elem --name "DefaultFileName" --value 'skan_$(YYYY)-$(MM)-$(DD).jpg' /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig/ImageSettings" --type elem --name "TiffCompression" --value "Auto" /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig/ImageSettings" --type elem --name "SinglePageTiff" --value "true" /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig" --type elem --name "PdfSettings" /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig/PdfSettings" --type elem --name "DefaultFileName" --value 'skan_$(YYYY)-$(MM)-$(DD).pdf' /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig/PdfSettings" --type elem --name "Metadata" /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig/PdfSettings/Metadata" --type elem --name "Author" --value "Instytut Botaniki PAN" /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig/PdfSettings/Metadata" --type elem --name "Creator" --value "" /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig/PdfSettings/Metadata" --type elem --name "Keywords" --value "" /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig/PdfSettings/Metadata" --type elem --name "Subject" --value "Zeskanowane obrazy" /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig/PdfSettings/Metadata" --type elem --name "Title" --value "Zeskanowane obrazy" /usr/lib/naps2/appsettings.xml 2>/dev/null
#xmlstarlet edit --inplace --subnode "/AppConfig/PdfSettings" --type elem --name "SinglePageTiff" --value "true" /usr/lib/naps2/appsettings.xml 2>/dev/null
xmlstarlet edit --inplace --update "/AppConfig/OcrDefaultLanguage" --value "pol+eng" /usr/lib/naps2/appsettings.xml 2>/dev/null
xmlstarlet edit --inplace --update "/AppConfig/ComponentsPath" --value "/usr/lib/naps2/components" /usr/lib/naps2/appsettings.xml 2>/dev/null
mkdir -p /usr/lib/naps2/components/tesseract4/{best,fast}
curl --no-progress-meter --retry 3 -Lo /usr/lib/naps2/components/tesseract4/best/pol.traineddata https://github.com/tesseract-ocr/tessdata_best/raw/refs/heads/main/pol.traineddata
curl --no-progress-meter --retry 3 -Lo /usr/lib/naps2/components/tesseract4/best/eng.traineddata https://github.com/tesseract-ocr/tessdata_best/raw/refs/heads/main/eng.traineddata
ln -sf /usr/share/tesseract/tessdata/pol.traineddata /usr/lib/naps2/components/tesseract4/fast/pol.traineddata
ln -sf /usr/share/tesseract/tessdata/eng.traineddata /usr/lib/naps2/components/tesseract4/fast/eng.traineddata
