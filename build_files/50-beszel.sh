#!/usr/bin/bash

set -ouex pipefail

curl --retry 3 -sSL \
    "https://github.com/henrygd/beszel/releases/latest/download/beszel-agent_$(uname -s)_$(uname -m | sed -e 's/x86_64/amd64/' -e 's/armv6l/arm/' -e 's/armv7l/arm/' -e 's/aarch64/arm64/').tar.gz" \
    | tar -xz -O beszel-agent | tee /usr/bin/beszel-agent >/dev/null
chmod +x /usr/bin/beszel-agent
touch /usr/share/botany/beszel-agent.env
echo "HUB_URL=${BESZEL_HUB_URL}" >> /usr/share/botany/beszel-agent.env
echo "TOKEN=${BESZEL_TOKEN}" >> /usr/share/botany/beszel-agent.env
echo "KEY=${BESZEL_KEY}" >> /usr/share/botany/beszel-agent.env
systemctl enable beszel-agent.service
