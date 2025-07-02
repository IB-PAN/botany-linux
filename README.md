# Botany Linux

Desktop Linux images for W. Szafer Institute of Botany.

## How to Install

Use the installation method for the respective upstream, Aurora, uCore, etc.

Add registry authorization:

```shell
echo "{\"auths\":{\"${IMAGE_REGISTRY}\":{\"auth\":\"`echo -n "${REGISTRY_PULLER_USER}:${REGISTRY_PULLER_PASSWORD}" | base64`\"}}}" | sudo tee /etc/ostree/auth.json
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

Then do:

```shell
ujust install-system-flatpaks
```

## Verification

These images are signed with sigstore's [cosign](https://docs.sigstore.dev/cosign/overview/) using. You can verify the signature by running the following command:

```shell
cosign verify --key cosign.pub ${IMAGE_REGISTRY}/botany-linux:TAG
```
