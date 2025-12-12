#!/usr/bin/bash

set -ouex pipefail

# Sigillum
SIGILLUM_SIGN_VERSION="1.11.31"
SIGILLUM_MANAGER_VERSION="1.0.12"
curl --no-progress-meter --retry 5 -Lo /tmp/Sigillum.run https://sigillum.pl/binaries/content/assets/Pliki/Sigillum_sign_od_2022/Linux/Sigillum_${SIGILLUM_SIGN_VERSION}.run &
curl --no-progress-meter --retry 5 -Lo /tmp/Sigman.run https://sigillum.pl/binaries/content/assets/Pliki/Sigman/Linux/Sigman_${SIGILLUM_MANAGER_VERSION}.run &
wait
chmod +x /tmp/{Sigillum,Sigman}.run
/tmp/Sigillum.run --confirm-command --accept-licenses --default-answer --auto-answer OverwriteTargetDirectory=Yes,installationErrorWithCancel=Ignore install
/tmp/Sigman.run --root "/opt/sigman" --confirm-command --accept-licenses --default-answer --auto-answer OverwriteTargetDirectory=Yes,installationErrorWithCancel=Ignore install
rm /tmp/{Sigillum,Sigman}.run
sed -i '/^Version=.*$/d' /etc/xdg/autostart/sigillum_monitor.desktop
desktop-file-edit --set-key=X-GNOME-Autostart-enabled --set-value="false" /etc/xdg/autostart/sigillum_monitor.desktop
desktop-file-edit --set-key=Hidden --set-value="true" /etc/xdg/autostart/sigillum_monitor.desktop
# not sure if the below actually does anything, shrug
# TODO: experiment with those when needed and when having access to a test card
##ln -s /opt/sigman/sigillum-pkcs11-64.so /usr/lib64/pkcs11/sigillum-pkcs11-64.so
##echo -e "module: sigillum-pkcs11-64.so\ntrust-policy: yes" > /usr/share/p11-kit/modules/sigillum.module
##echo -e "\n\nlibrary=/usr/lib64/pkcs11/sigillum-pkcs11-64.so\nname=Sigillum (64 bits)\nNSS=slotParams={0xffffffff=[slotFlags=PublicCerts] 0x0=[slotFlags=PublicCerts] 0x1=[slotFlags=PublicCerts] 0x2=[slotFlags=PublicCerts] 0x3=[slotFlags=PublicCerts] 0x4=[slotFlags=PublicCerts] 0x5=[slotFlags=PublicCerts] 0x6=[slotFlags=PublicCerts] 0x7=[slotFlags=PublicCerts] 0x8=[slotFlags=PublicCerts] 0x9=[slotFlags=PublicCerts] 0xa=[slotFlags=PublicCerts] 0xb=[slotFlags=PublicCerts] 0xc=[slotFlags=PublicCerts] 0xd=[slotFlags=PublicCerts] 0xe=[slotFlags=PublicCerts] 0xf=[slotFlags=PublicCerts]}" >> /etc/pki/nssdb/pkcs11.txt
# ~/.pki/nssdb/pkcs11.txt | ~/.mozilla/firefox/*.default*/pkcs11.txt | ...
# modutil -dbdir sql:$HOME/.pki/nssdb/ -add "eToken" -libfile /usr/lib/libeToken.so
