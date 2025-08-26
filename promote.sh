#!/bin/bash

source .env

TAG_OLD="latest"
TAG_NEW="prod"

#CONTENT_TYPE="application/vnd.docker.distribution.manifest.v2+json"
CONTENT_TYPE="application/vnd.oci.image.manifest.v1+json"
U="${REGISTRY_USER}:${REGISTRY_PASSWORD}"

printf "\n\n\nGetting manifest...\n\n\n\n"
curl -o /tmp/manifest.json -v -H "Accept: ${CONTENT_TYPE}" -u "${U}" --no-progress-meter "https://${IMAGE_REGISTRY}/v2/${IMAGE_NAME}/manifests/${TAG_OLD}"

#printf "\n\n\nResponse:\n\n"
#jq --color-output < /tmp/manifest.json

printf "\n\n\nSubmitting manifest...\n\n\n\n"
curl -v -X PUT -H "Content-Type: ${CONTENT_TYPE}" --data-binary "@/tmp/manifest.json" -u "${U}" --no-progress-meter "https://${IMAGE_REGISTRY}/v2/${IMAGE_NAME}/manifests/${TAG_NEW}"

rm /tmp/manifest.json
