#!/usr/bin/bash

set -ouex pipefail

# Scrutiny agent
curl --no-progress-meter -Lo /usr/bin/scrutiny-collector-metrics https://github.com/AnalogJ/scrutiny/releases/latest/download/scrutiny-collector-metrics-linux-amd64
chmod +x /usr/bin/scrutiny-collector-metrics
echo "COLLECTOR_API_ENDPOINT=${SCRUTINY_COLLECTOR_API_ENDPOINT}" > /usr/share/botany/scrutiny-collector.env
systemctl enable scrutiny-collector.timer
