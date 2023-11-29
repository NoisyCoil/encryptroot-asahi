#!/bin/sh

set -e

IMAGE_PATH="$(tests/unpack-image.sh)"
ROOTLOOP="$(losetup 2>/dev/null | grep "$IMAGE_PATH/root.img" 2>&1 | cut -d' ' -f1 2>/dev/null)"
[ -n "$ROOTLOOP" ] || ROOTLOOP="$(sudo losetup -Pf --show "$IMAGE_PATH/root.img" 2>/dev/null)"
BOOTLOOP="$(losetup 2>/dev/null | grep "$IMAGE_PATH/boot.img" 2>&1 | cut -d' ' -f1 2>/dev/null)"
[ -n "$BOOTLOOP" ] || BOOTLOOP="$(sudo losetup -Pf --show "$IMAGE_PATH/boot.img" 2>/dev/null)"

echo "$ROOTLOOP $BOOTLOOP"
