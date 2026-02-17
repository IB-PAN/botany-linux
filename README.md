# Botany Linux

Atomic desktop Linux images for internal use of the W. Szafer Institute of Botany, Polish Academy of Sciences. Based on Universal Blue's [Aurora](https://github.com/ublue-os/aurora) (with KDE).

The images are built using GitHub Actions CI, but pushed into a private registry accessible only to authorized machines. Using bootc/rpm-ostree technology allows for simple and predictable updates, while enabling seamless yet powerful management and customization capabilities. The images are signed with cosign and a custom Secure Boot MOK key is used to sign the kernel and its modules, being imported into the target machines to verify the boot chain. Yubikeys are used to authorize SSH access. Required software and extra packages are pre-installed into the image, with some software installed as Flatpaks (notably the web browsers). Firefox is set up with enterprise policies and a [helper internal add-on](https://github.com/IB-PAN/botany-browser-extension-linux). A KDE branding package is included too. Automatic Snapper snapshots are configured (with semi-dynamic retention policy).

![Screenshot](https://github.com/user-attachments/assets/2e030ec8-3c9f-4e43-a1f7-ea0dfca4e5d8)

## How to install (internal instruction)

We are currently missing a dedicated installer (the ISOs we used technically worked, but there were some issues). The current method of installation is to first install protoplast Fedora Kinoite with their upstream ISO, and then rebase to our image. Create user `botany_adm` (display name `BOTANY_ADM`), set a password and add it to the wheel group. Don't set password for root. Set machine hostname.

Import Secure Boot MOK key (in a directory with `MOK.der`):

```shell
mokutil --timeout -1
ENROLLMENT_PASSWORD=botany
echo -e "$ENROLLMENT_PASSWORD\n$ENROLLMENT_PASSWORD" | mokutil --import "MOK.der"
```

Add registry authorization:

```shell
echo "{\"auths\":{\"${IMAGE_REGISTRY}\":{\"auth\":\"`echo -n "${REGISTRY_PULLER_USER}:${REGISTRY_PULLER_PASSWORD}" | base64 -w0`\"}}}" | sudo tee /etc/ostree/auth.json
```

Switch without signature verification first:

```shell
sudo bootc switch ${IMAGE_REGISTRY}/botany-linux:${TAG}
```

where `${TAG}` is `latest` or `prod`.

Reboot.

Then with verification:

```shell
sudo bootc switch --enforce-container-sigpolicy ${IMAGE_REGISTRY}/botany-linux:${TAG}
```

Then verify `/usr/lib/ostree/auth.json` exists on the new system and you may `sudo rm /etc/ostree/auth.json` now:

```shell
[ -f /usr/lib/ostree/auth.json ] && sudo rm /etc/ostree/auth.json || echo Fail
```

You may also change BTRFS filesystem label like this:

```shell
sudo btrfs filesystem label /var botany_linux_123
```

## Verification

These images are signed with sigstore's [cosign](https://docs.sigstore.dev/cosign/overview/) using. You can verify the signature by running the following command:

```shell
cosign verify --key cosign.pub ${IMAGE_REGISTRY}/botany-linux:TAG
```
