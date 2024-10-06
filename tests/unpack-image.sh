#!/bin/sh

set -e

# For Debian users with default PATH
export PATH="$PATH:/usr/sbin"

DEBIAN_OS=""
MNTDIR=""
for arg in "$@"; do
    if [ "$arg" = "--debian" ]; then
        DEBIAN_OS="1"
        break
    fi
done

remaster_image_cleanup() {
    sudo sync
    if [ -n "$MNTDIR" ] && mountpoint "$MNTDIR" >/dev/null 2>&1; then
        sudo umount "$MNTDIR" >&2
    fi
    if [ -n "$LODEVICE" ] && losetup "$LODEVICE" >/dev/null 2>&1; then
        sudo losetup -d "$LODEVICE" >&2
    fi
}

# Works around update-grub being unable to deal with filesystems not
# in a partitioned disk in Debian
remaster_image() {
    dd if=/dev/zero of="images/$IMAGE_ID/disk.img" bs=16M count=384 status=progress
    sudo sync
    printf "g\nn\n\n\n+64M\nn\n\n\n+2G\nn\n\n\n\nw\n" | fdisk "images/$IMAGE_ID/disk.img"
    trap 'remaster_image_cleanup;' EXIT INT TERM QUIT HUP ABRT
    LODEVICE="$(sudo losetup --show -Pf "images/$IMAGE_ID/disk.img" 2>/dev/null)"
    EFIP="${LODEVICE}p1"
    BOOTP="${LODEVICE}p2"
    ROOTP="${LODEVICE}p3"
    sudo mkfs.vfat "$EFIP"
    MNTDIR="$(mktemp -d)"
    sudo mount "$EFIP" "$MNTDIR"
    sudo cp -r "images/$IMAGE_ID/esp/"* "$MNTDIR"
    sudo dd if="images/$IMAGE_ID/boot.img" of="$BOOTP" bs=16M status=progress
    sudo dd if="images/$IMAGE_ID/root.img" of="$ROOTP" bs=16M status=progress
    sudo sync
    sudo e2fsck -f -y "$BOOTP"
    sudo resize2fs "$BOOTP"
    sudo e2fsck -f -y "$ROOTP"
    sudo resize2fs "$ROOTP"
    trap - EXIT INT TERM QUIT HUP ABRT
    remaster_image_cleanup
}

IMAGE_UUID="${IMAGE_UUID:-"$(uuidgen | head -c 8)"}"

PACKAGE_PATH="$(tests/download-image.sh "$@")"
IMAGE_ID="$(basename "$PACKAGE_PATH" .zip)-$IMAGE_UUID"
[ -d "images/$IMAGE_ID" ] || unzip "$PACKAGE_PATH" -d "images/$IMAGE_ID" >&2
if [ -n "$DEBIAN_OS" ] && ! [ -f "images/$IMAGE_ID/disk.img" ]; then
    remaster_image >&2
fi
echo "images/$IMAGE_ID"
