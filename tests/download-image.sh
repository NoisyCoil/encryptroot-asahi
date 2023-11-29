#!/bin/sh

set -e

exit_error() {
    echo "$1" >&2
    exit 1
}

IMAGE="${IMAGE:-"Fedora Asahi Remix 39 Minimal"}"
BASEURL="https://alx.sh"
INSTALLER_DATA_LINK="$(curl -L "$BASEURL" 2>/dev/null | grep INSTALLER_DATA= 2>/dev/null | sed -E 's|^.*INSTALLER_DATA=(.*)$|\1|' 2>/dev/null)"
[ -n "$INSTALLER_DATA_LINK" ] || exit_error "empty installer data link"
PACKAGE_URL="$(curl -L "$INSTALLER_DATA_LINK" 2>/dev/null | jq -r ".os_list[] | select(.name == \"$IMAGE\") | .package" 2>/dev/null)"
[ -n "$PACKAGE_URL" ] || exit_error "empty package url"
PACKAGE="$(basename "$PACKAGE_URL" 2>/dev/null)"
mkdir images >/dev/null 2>&1 || true
[ -e "images/$PACKAGE" ] || wget -O "images/$PACKAGE" "$PACKAGE_URL" >&2
echo "images/$PACKAGE"
