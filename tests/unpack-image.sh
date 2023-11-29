#!/bin/sh

set -e

IMAGE_UUID="${IMAGE_UUID:-"$(uuidgen | head -c 8)"}"

PACKAGE_PATH="$(tests/download-image.sh)"
IMAGE_ID="$(basename "$PACKAGE_PATH" .zip)-$IMAGE_UUID"
[ -d "images/$IMAGE_ID" ] || unzip "$PACKAGE_PATH" -d "images/$IMAGE_ID" >&2
echo "images/$IMAGE_ID"
