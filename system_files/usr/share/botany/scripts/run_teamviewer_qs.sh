#!/bin/bash

set -x

pushd /tmp

dbusRef=`kdialog --title "TeamViewer Quick Support" --progressbar "Pobieranie i uruchamianie, proszę czekać..." 0`
qdbus-qt6 $dbusRef org.kde.kdialog.ProgressDialog.showCancelButton false

wget https://dl.teamviewer.com/download/linux/version_15x/teamviewer_qs.tar.gz
tar xaf teamviewer_qs.tar.gz
rm -f teamviewer_qs.tar.gz

cd teamviewerqs/

mkdir -p ~/.config/teamviewer
#mkdir -p ~/.local/share/teamviewer15/logfiles

rm -rf ./config
#rm -rf ./logfiles

ln -sf ~/.config/teamviewer ./config
#ln -sf ~/.local/share/teamviewer15/logfiles ./logfiles

./teamviewer &
popd

sleep 4
qdbus-qt6 $dbusRef close || true
