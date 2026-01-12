#!/usr/bin/bash

set -ouex pipefail

curl --retry 3 -sSL \
    "https://github.com/henrygd/beszel/releases/latest/download/beszel-agent_$(uname -s)_$(uname -m | sed -e 's/x86_64/amd64/' -e 's/armv6l/arm/' -e 's/armv7l/arm/' -e 's/aarch64/arm64/').tar.gz" \
    | tar -xz -O beszel-agent | tee /usr/bin/beszel-agent >/dev/null
chmod +x /usr/bin/beszel-agent
touch /usr/share/botany/beszel-agent.env
echo "HUB_URL=${BESZEL_HUB_URL}" >> /usr/share/botany/beszel-agent.env
echo "${BESZEL_TOKEN}" > /usr/lib/credstore/beszel_token
echo "${BESZEL_KEY}" > /usr/lib/credstore/beszel_key
chown root:root /usr/lib/credstore/beszel_{token,key}
chmod 600 /usr/lib/credstore/beszel_{token,key}
systemctl enable beszel-agent.service
