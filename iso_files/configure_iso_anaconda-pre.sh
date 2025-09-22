#!/usr/bin/env bash

set -eoux pipefail

mkdir -p $(realpath /root)
mkdir -p /root/.docker
mkdir -p /root/.config/containers
cp /usr/lib/ostree/auth.json /root/.config/containers/auth.json
cp /usr/lib/ostree/auth.json /root/.docker/config.json
