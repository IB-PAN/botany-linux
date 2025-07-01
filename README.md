# Botany Linux

Desktop Linux images for W. Szafer Institute of Botany.

## How to Install

Use the installation method for the respective upstream, Bluefin, uCore, etc.

```
sudo bootc switch --enforce-container-sigpolicy ${IMAGE_REGISTRY}/botany-linux:TAG
```

where `TAG` is `latest` or `prod`.

## Verification

These images are signed with sigstore's [cosign](https://docs.sigstore.dev/cosign/overview/) using. You can verify the signature by running the following command:

```
cosign verify --key cosign.pub ${IMAGE_REGISTRY}/botany-linux:TAG
```
