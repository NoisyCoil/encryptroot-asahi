#!/bin/sh

set -e

exit_error() {
    echo "Error: $1" >&2
    exit 1
}

cleanup() {
    if [ -n "$MNTDIR" ]; then
        findmnt "$MNTDIR/boot" >/dev/null 2>&1 && sudo umount "$MNTDIR/boot"
        findmnt "$MNTDIR" >/dev/null 2>&1 && sudo umount "$MNTDIR"
        rm -df "$MNTDIR"
    fi
    [ -b "/dev/mapper/$IMAGE_NUUID" ] && sudo cryptsetup close "$IMAGE_NUUID"
}

echo "*** Testing encryption process on USB drive ***"
echo

git submodule update --init --recursive --remote || true

CWD="$(pwd)"
cd tests/asahi-fedora-usb
sudo ./build.sh -d "$1"
cd "$CWD"

ROOTLABEL="fedora-usb-root"
BOOTLABEL="fedora-usb-boot"

ROOTDISK="${1}3"
BOOTDISK="${1}2"

[ "$(lsblk -no LABEL "$ROOTDISK")" = "$ROOTLABEL" ] || exit_error "wrong root disk"
[ "$(lsblk -no LABEL "$BOOTDISK")" = "$BOOTLABEL" ] || exit_error "wrong boot disk"

trap 'cleanup; exit;' EXIT INT TERM QUIT ABRT

PASSWORD=complicatedpassword3945

sudo src/encryptroot.asahi --ext4 --root-label "$ROOTLABEL" --boot-label "$BOOTLABEL" -v "$ROOTDISK" "$BOOTDISK" <<EOF


$PASSWORD
$PASSWORD
$PASSWORD
EOF

IMAGE_NUUID="fedora-root-$(uuidgen | head -c 8)"

lsblk -ndo FSTYPE "$ROOTDISK" | grep crypto_LUKS >/dev/null 2>&1 || exit_error "unencrypted root disk"
sudo cryptsetup luksDump "$ROOTDISK" | grep -E "Requirements:\s*online-reencrypt" >/dev/null 2>&1 && exit_error "incomplete root disk encryption"

LUKS_UUID="$(sudo cryptsetup luksUUID "$ROOTDISK")"

sudo cryptsetup open "$ROOTDISK" "$IMAGE_NUUID" <<EOF
$PASSWORD
EOF

MNTDIR="$(mktemp -d)"
sudo mount "/dev/mapper/$IMAGE_NUUID" "$MNTDIR"
sudo mount "$BOOTDISK" "$MNTDIR/boot"

for file in "/etc/crypttab" "/etc/default/grub" "/boot/grub2/grub.cfg"; do
    sudo grep "$LUKS_UUID" "$MNTDIR$file" >/dev/null 2>&1 || exit_error "luksUUID not in $file"
done
sudo grep -R "$LUKS_UUID" "$MNTDIR/boot/loader/entries" >/dev/null 2>&1 || exit_error "luksUUID not in /boot/loader/entries/"

trap - EXIT

cleanup
echo
echo "*** Encryption process test passed on USB drive ***"
