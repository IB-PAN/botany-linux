# Reboot to current boot option (even if regular boot order is different, such as in dual-booting)
[group('Botany')]
reboot-to-current:
    #!/usr/bin/bash
    CURRENT=$(efibootmgr | awk '/^BootCurrent: [0-9]+$/ { print $2 }')
    BOOT_ORDER_FIRST=$(efibootmgr | awk -F, '/^BootOrder: ([0-9,]+)/ { sub(/^BootOrder: /, ""); print $1 }')
    if [[ $CURRENT ]]; then
        if [[ "$CURRENT" != "$BOOT_ORDER_FIRST" ]]; then
            efibootmgr --bootnext $CURRENT | grep -E "^Boot(First|Current|Next|Order|${CURRENT}|${BOOT_ORDER_FIRST})"
            echo
        else
            efibootmgr | grep -E "^Boot(First|Current|Next|Order|${CURRENT}|${BOOT_ORDER_FIRST})"
            echo
            echo "Current boot option is already first in the boot order. Not doing anything."
        fi
    fi
    read -rs -p "Press enter to continue..."
    systemctl reboot
