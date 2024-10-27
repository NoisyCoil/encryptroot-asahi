#!/bin/sh

set -e

exit_error() {
    echo "Error: $1" >&2
    exit 1
}

cleanup() {
    if [ -n "$MNTDIR" ]; then
        findmnt "$MNTDIR/boot" >/dev/null 2>&1 && sudo umount "$MNTDIR/boot"
        findmnt "$MNTDIR/home" >/dev/null 2>&1 && sudo umount "$MNTDIR/home"
        findmnt "$MNTDIR" >/dev/null 2>&1 && sudo umount "$MNTDIR"
        rm -df "$MNTDIR"
    fi
    [ -b "/dev/mapper/$IMAGE_NUUID" ] && sudo cryptsetup close "$IMAGE_NUUID"
    { losetup 2>/dev/null | grep "$ROOTLOOP" >/dev/null 2>&1; } && sudo losetup -d "$ROOTLOOP"
    { losetup 2>/dev/null | grep "$BOOTLOOP" >/dev/null 2>&1; } && sudo losetup -d "$BOOTLOOP"
}

echo "*** Testing encryption process on raw image ***"
echo

LOOPDEVICES="$(tests/mount-image.sh)"
ROOTLOOP="$(echo "$LOOPDEVICES" | cut -d' ' -f1)"
BOOTLOOP="$(echo "$LOOPDEVICES" | cut -d' ' -f2)"

trap 'cleanup; exit;' EXIT INT TERM QUIT ABRT

PASSWORD=complicatedpassword3945

sudo src/encryptroot.asahi -v "$@" "$ROOTLOOP" "$BOOTLOOP" <<EOF


$PASSWORD
$PASSWORD
$PASSWORD
EOF

echo
echo "Finished encryption. Starting tests."

IMAGE_NUUID="fedora-root-$(uuidgen | head -c 8)"

lsblk -ndo FSTYPE "$ROOTLOOP" | grep crypto_LUKS >/dev/null 2>&1 || exit_error "unencrypted root disk"
sudo cryptsetup luksDump "$ROOTLOOP" | grep -E "Requirements:\s*online-reencrypt" >/dev/null 2>&1 && exit_error "incomplete root disk encryption"

echo "Check: root disk encryption is complete."

LUKS_UUID="$(sudo cryptsetup luksUUID "$ROOTLOOP")"

sudo cryptsetup open "$ROOTLOOP" "$IMAGE_NUUID" <<EOF
$PASSWORD
EOF

echo "Check: root disk can be decrypted."

MNTDIR="$(mktemp -d)"
sudo mount -o subvol=root "/dev/mapper/$IMAGE_NUUID" "$MNTDIR"
sudo mount -o subvol=home "/dev/mapper/$IMAGE_NUUID" "$MNTDIR/home"
sudo mount "$BOOTLOOP" "$MNTDIR/boot"

for file in "/etc/crypttab" "/etc/default/grub" "/boot/grub2/grub.cfg"; do
    sudo grep "$LUKS_UUID" "$MNTDIR$file" >/dev/null 2>&1 || exit_error "luksUUID not in $file"
done
sudo grep -R "$LUKS_UUID" "$MNTDIR/boot/loader/entries" >/dev/null 2>&1 || exit_error "luksUUID not in /boot/loader/entries/"

trap - EXIT

echo "Check: luksUUID found in config files."

cleanup
echo
echo "*** Encryption process test passed on raw image ***"
