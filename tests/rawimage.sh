#!/bin/sh

set -e

# For Debian users with default PATH
export PATH="$PATH:/usr/sbin"

exit_error() {
    echo "Error: $1" >&2
    exit 1
}

cleanup() {
    sudo sync
    if [ -n "$MNTDIR" ]; then
        findmnt "$MNTDIR/boot" >/dev/null 2>&1 && sudo umount "$MNTDIR/boot"
        findmnt "$MNTDIR/home" >/dev/null 2>&1 && sudo umount "$MNTDIR/home"
        findmnt "$MNTDIR" >/dev/null 2>&1 && sudo umount "$MNTDIR"
        rm -df "$MNTDIR"
    fi
    [ -b "/dev/mapper/$IMAGE_NUUID" ] && sudo cryptsetup close "$IMAGE_NUUID"
    if [ -z "$DEBIAN_ARG" ]; then
        { losetup 2>/dev/null | grep "$ROOTLOOP" >/dev/null 2>&1; } && sudo losetup -d "$ROOTLOOP"
        { losetup 2>/dev/null | grep "$BOOTLOOP" >/dev/null 2>&1; } && sudo losetup -d "$BOOTLOOP"
    else
        LODEV="$(echo "$ROOTLOOP" | sed -E 's|p[0-9]+$||')"
        [ -n "$LODEV" ] && { losetup 2>/dev/null | grep "$LODEV" >/dev/null 2>&1; } && sudo losetup -d "$LODEV"
    fi
}

DEBIAN_ARG=""
for arg in "$@"; do
    if [ "$arg" = "--debian" ]; then
        DEBIAN_ARG="--debian"
        DEBIAN_LABEL=" (Debian mode)"
        break
    fi
done

echo "*** Testing encryption of raw image${DEBIAN_LABEL} ***"
echo

#shellcheck disable=2086
LOOPDEVICES="$(tests/mount-image.sh $DEBIAN_ARG)"
ROOTLOOP="$(echo "$LOOPDEVICES" | cut -d' ' -f1)"
BOOTLOOP="$(echo "$LOOPDEVICES" | cut -d' ' -f2)"

sleep 2

trap 'cleanup;' EXIT INT TERM QUIT ABRT

PASSWORD=complicatedpassword3945

[ -z "$DEBIAN_ARG" ] || DEVICE_NAME_OPT="-d debian-root-$(uuidgen | head -c 8)"

# shellcheck disable=2086
sudo src/encryptroot.asahi -v $DEVICE_NAME_OPT "$@" "$ROOTLOOP" "$BOOTLOOP" <<EOF


$PASSWORD
$PASSWORD
$PASSWORD
EOF

sudo sync

echo
echo "Finished encryption. Starting tests."
echo

IMAGE_NUUID="root-$(uuidgen | head -c 12)"

lsblk -ndo FSTYPE "$ROOTLOOP" | grep crypto_LUKS >/dev/null 2>&1 || exit_error "unencrypted root disk"
sudo cryptsetup luksDump "$ROOTLOOP" | grep -E "Requirements:\s*online-reencrypt" >/dev/null 2>&1 && exit_error "incomplete root disk encryption"

echo "Check: root disk encryption is complete."

LUKS_UUID="$(sudo cryptsetup luksUUID "$ROOTLOOP")"

sudo cryptsetup open "$ROOTLOOP" "$IMAGE_NUUID" <<EOF
$PASSWORD
EOF

echo "Check: root disk can be decrypted."

GRUB_DIR="grub"

MNTDIR="$(mktemp -d)"
if [ -z "$DEBIAN_ARG" ]; then
    sudo mount -o subvol=root "/dev/mapper/$IMAGE_NUUID" "$MNTDIR"
    sudo mount -o subvol=home "/dev/mapper/$IMAGE_NUUID" "$MNTDIR/home"
    GRUB_DIR="${GRUB_DIR}2"
else
    sudo mount "/dev/mapper/$IMAGE_NUUID" "$MNTDIR"
fi
sudo mount "$BOOTLOOP" "$MNTDIR/boot"

for file in "/etc/crypttab" "/etc/default/grub" "/boot/$GRUB_DIR/grub.cfg"; do
    sudo grep "$LUKS_UUID" "$MNTDIR$file" >/dev/null 2>&1 || exit_error "luksUUID not in $file"
done
if [ -z "$DEBIAN_ARG" ]; then
    sudo grep -R "$LUKS_UUID" "$MNTDIR/boot/loader/entries" >/dev/null 2>&1 || exit_error "luksUUID not in /boot/loader/entries/"
fi

trap - EXIT INT TERM QUIT ABRT

echo "Check: luksUUID found in config files."

cleanup
echo
echo "*** Encryption of raw image test passed ***"
