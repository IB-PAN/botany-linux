#!/bin/bash

#WINEPREFIX=~/.local/share/wineprefixes/msoffice2010-powerpoint-viewer WINEARCH=win32 ~/.local/share/wineprefixes/msoffice2010-powerpoint-viewer/drive_c/Program\ Files/Microsoft\ Office/Office14/PPTVIEW.EXE Norma-prawna-a-norma-moralna.pptx

set -x

mkdir /tmp/msoffice2010-powerpoint-viewer
pushd /tmp/msoffice2010-powerpoint-viewer

mkdir -p ~/.local/share/wineprefixes
WINEPREFIX=~/.local/share/wineprefixes/msoffice2010-powerpoint-viewer WINEARCH=win32 wine wineboot --init
WINEPREFIX=~/.local/share/wineprefixes/msoffice2010-powerpoint-viewer WINEARCH=win32 winetricks winxp
WINEPREFIX=~/.local/share/wineprefixes/msoffice2010-powerpoint-viewer WINEARCH=win32 winetricks settings fontsmooth=rgb
WINEPREFIX=~/.local/share/wineprefixes/msoffice2010-powerpoint-viewer WINEARCH=win32 winetricks msxml3 msxml6

wget https://download.dpcdn.pl/archiwum/PowerPointViewer.exe
wget https://download.microsoft.com/download/b/4/a/b4aac00b-e1d8-4deb-af7a-844bf59e464a/ppviewersp2010-kb2687456-fullfile-x86-en-us.exe
wget https://download.microsoft.com/download/c/f/7/cf7662b5-f9e1-4c08-b5ff-3428dfff87dd/pptview2010-kb4011191-fullfile-x86-glb.exe

WINEPREFIX=~/.local/share/wineprefixes/msoffice2010-powerpoint-viewer WINEARCH=win32 wine PowerPointViewer.exe /passive /norestart
WINEPREFIX=~/.local/share/wineprefixes/msoffice2010-powerpoint-viewer WINEARCH=win32 wine ppviewersp2010-kb2687456-fullfile-x86-en-us.exe /passive /norestart
WINEPREFIX=~/.local/share/wineprefixes/msoffice2010-powerpoint-viewer WINEARCH=win32 wine pptview2010-kb4011191-fullfile-x86-glb.exe /passive /norestart

cat > ./override-dll.reg <<_EOF_
REGEDIT4

[HKEY_CURRENT_USER\\Software\\Wine\\DllOverrides]
"*riched20"="native,builtin"
_EOF_
WINEPREFIX=~/.local/share/wineprefixes/msoffice2010-powerpoint-viewer WINEARCH=win32 wine "C:\\windows\\regedit.exe" /S ./override-dll.reg
# if the prefix was 64-bit (wow64) (run IN ADDITION to the one on top with the other regedit.exe):
#WINEPREFIX=~/.local/share/wineprefixes/msoffice2010-powerpoint-viewer WINEARCH=win64 wine "C:\\windows\\syswow64\\regedit.exe" /S
rm ./override-dll.reg

popd
rm -rf /tmp/msoffice2010-powerpoint-viewer
