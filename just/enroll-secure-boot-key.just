# Enroll Botany signing key for secure boot
[group('Botany')]
enroll-secure-boot-key:
    botany_sudo mokutil --timeout -1
    echo -e "botany\nbotany" | botany_sudo mokutil --import /etc/pki/akmods/certs/botany.der >/dev/null
    botany_sudo mokutil --list-new
    echo -e '\nAt next reboot, the mokutil UEFI menu UI will be displayed (*QWERTY* keyboard input and navigation).\nThen, select "Enroll MOK", and input "botany" as the password.'
