#!/usr/bin/bash

set -ouex pipefail

source /ctx/build_files/build-helpers.sh

# Dependencies

pdnf install elfutils-libelf elfutils-libelf-devel libbpf libbpf-devel fmt fmt-devel spdlog spdlog-devel nlohmann-json-devel

# ananicy-cpp

git clone --recursive --depth 1 https://gitlab.com/ananicy-cpp/ananicy-cpp.git /tmp/ananicy-cpp

pushd /tmp/ananicy-cpp

cmake -S . -Bbuild \
    -GNinja \
    -DCMAKE_BUILD_TYPE=None \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DUSE_EXTERNAL_SPDLOG=ON \
    -DUSE_EXTERNAL_JSON=ON \
    -DUSE_EXTERNAL_FMTLIB=ON \
    -DENABLE_SYSTEMD=ON \
    -DUSE_BPF_PROC_IMPL=ON \
    -DBPF_BUILD_LIBBPF=OFF

cmake --build build --target ananicy-cpp

DESTDIR="/" cmake --install build --component Runtime

popd
rm -rf /tmp/ananicy-cpp

# ananicy-rules

curl --no-progress-meter --retry 3 -Lo /tmp/ananicy-rules.zip https://github.com/CachyOS/ananicy-rules/archive/refs/heads/master.zip
7z x -o/tmp/ /tmp/ananicy-rules.zip
rm /tmp/ananicy-rules.zip
mv /tmp/ananicy-rules-master /etc/ananicy.d
rm -rf /etc/ananicy.d/{.github,LICENSE,README.md}

# Enable the service

systemctl enable ananicy-cpp.service
