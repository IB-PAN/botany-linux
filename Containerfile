# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /build_files
COPY just /just
COPY MOK.der MOK.crt MOK.key u2f_keys /

# Base Image
FROM ghcr.io/ublue-os/aurora:stable
COPY --chown=root:root system_files /

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=tmpfs,dst=/boot \
    --mount=type=tmpfs,dst=/var \
    --mount=type=cache,dst=/var/cache/libdnf5 \
    --mount=type=bind,source=.env,target=/.env \
    /ctx/build_files/build.sh

### LINTING
## Verify final image and contents are correct.
RUN --network=none \
    bootc container lint --no-truncate

CMD ["/sbin/init"]
