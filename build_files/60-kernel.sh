#!/bin/bash

set -ouex pipefail

# Deploy Secure Boot MOK keys
DER_PATH=/etc/pki/akmods/certs/botany.der
cp /ctx/MOK.der "$DER_PATH"
if [ -f "/etc/pki/akmods/certs/akmods-ublue.der" ]; then
    mv /etc/pki/akmods/certs/akmods-ublue.der /etc/pki/akmods/certs/akmods-ublue-original.der
fi
ln -s "$DER_PATH" /etc/pki/akmods/certs/akmods-ublue.der
mkdir -p /usr/share/ublue-os/etc/pki/akmods/certs/
ln -sf "$DER_PATH" /usr/share/ublue-os/etc/pki/akmods/certs/akmods-ublue.der
#jq --arg derpath "$DER_PATH" '.["der-path"] = ($derpath)' /etc/ublue-os/setup.json | sponge /etc/ublue-os/setup.json
#jq '.["check-secureboot"] = true' /etc/ublue-os/setup.json | sponge /etc/ublue-os/setup.json
#systemctl enable check-sb-key.service

# Sign kernel
PUBLIC_KEY_PATH="/ctx/MOK.crt"
PRIVATE_KEY_PATH="/ctx/MOK.key"
KERNEL_SIGN_FILE="/ctx/build_files/sign-file"
for VMLINUZ in /usr/lib/modules/*/vmlinuz; do
    KERNEL=$(basename $(dirname "$VMLINUZ"))
    sbsign --cert "$PUBLIC_KEY_PATH" --key "$PRIVATE_KEY_PATH" "$VMLINUZ" --output "$VMLINUZ"

    # Verify
    sbverify --list "$VMLINUZ"
    if ! sbverify --cert "$PUBLIC_KEY_PATH" "$VMLINUZ"; then
        exit 1
    fi

    # Sign modules
    for module in /usr/lib/modules/"${KERNEL}"/extra/*/*.ko*; do
        module_extension="${module##*.}"
        module_basename="${module%.*}"

        if [[ "$module_extension" == "xz" ]]; then
            xz --decompress --force "$module"
        elif [[ "$module_extension" == "gz" ]]; then
            gzip --decompress --force "$module"
        elif [[ "$module_extension" == "zst" ]]; then
            zstd --decompress --force --rm -T0 "$module"
        elif [[ "$module_extension" == "ko" ]]; then
            module_basename="${module_basename}.ko"
        fi

        "$KERNEL_SIGN_FILE" sha512 "$PRIVATE_KEY_PATH" "$PUBLIC_KEY_PATH" "$module_basename"
        
        if [[ "$module_extension" == "xz" ]]; then
            xz -C crc32 -f "$module_basename"
        elif [[ "$module_extension" == "gz" ]]; then
            gzip -9f "$module_basename"
        elif [[ "$module_extension" == "zst" ]]; then
            zstd -T0 --rm --long -15 "$module_basename"
        fi

        modinfo "$module" | grep -E '^filename:|signer:'
    done
done

# Regenerate initramfs
KERNEL_SUFFIX=""
QUALIFIED_KERNEL="$(rpm -qa | grep -P 'kernel-(|'"$KERNEL_SUFFIX"'-)(\d+\.\d+\.\d+)' | sed -E 's/kernel-(|'"$KERNEL_SUFFIX"'-)//')"
/usr/bin/dracut --no-hostonly --kver "$QUALIFIED_KERNEL" --reproducible -v --add ostree -f "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
chmod 0600 "/lib/modules/$QUALIFIED_KERNEL/initramfs.img"
