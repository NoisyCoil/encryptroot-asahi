#!/bin/sh

set -e

# For Debian users with default PATH
export PATH="$PATH:/usr/sbin"

DEBIAN_OS=""
ROOTLOOP=""
BOOTLOOP=""
LODEV=""
for arg in "$@"; do
    if [ "$arg" = "--debian" ]; then
        DEBIAN_OS="1"
        break
    fi
done

IMAGE_PATH="$(tests/unpack-image.sh "$@")"
if [ -z "$DEBIAN_OS" ]; then
    ROOTLOOP="$(losetup 2>/dev/null | grep "$IMAGE_PATH/root.img" 2>&1 | cut -d' ' -f1 2>/dev/null)"
    [ -n "$ROOTLOOP" ] || ROOTLOOP="$(sudo losetup -Pf --show "$IMAGE_PATH/root.img" 2>/dev/null)"
    BOOTLOOP="$(losetup 2>/dev/null | grep "$IMAGE_PATH/boot.img" 2>&1 | cut -d' ' -f1 2>/dev/null)"
    [ -n "$BOOTLOOP" ] || BOOTLOOP="$(sudo losetup -Pf --show "$IMAGE_PATH/boot.img" 2>/dev/null)"
else
    LODEV="$(losetup 2>/dev/null | grep "$IMAGE_PATH/disk.img" 2>&1 | cut -d' ' -f1 2>/dev/null)"
    [ -n "$LODEV" ] || LODEV="$(sudo losetup -Pf --show "$IMAGE_PATH/disk.img" 2>/dev/null)"
    BOOTLOOP="${LODEV}p2"
    ROOTLOOP="${LODEV}p3"
fi

echo "$ROOTLOOP $BOOTLOOP"
