#!/bin/sh

set -e

exit_error() {
    echo "$1" >&2
    exit 1
}

DEBIAN_OS=""
for arg in "$@"; do
    if [ "$arg" = "--debian" ]; then
        DEBIAN_OS="1"
        break
    fi
done

if [ -z "$DEBIAN_OS" ]; then
    IMAGE="${IMAGE:-"Fedora Asahi Remix 40 Minimal"}"
    BASE_URL="${BASE_URL:-"https://alx.sh"}"
    INSTALLER_URL="${INSTALLER_URL:-"$BASE_URL"}"
else
    IMAGE="${IMAGE:-"Debian Asahi GNU/Linux Testing minimal"}"
    BASE_URL="${BASE_URL:-"https://asahi.noisycoil.dev/debian"}"
    INSTALLER_URL="${INSTALLER_URL:-"$BASE_URL/install"}"
fi
INSTALLER_DATA_LINK="$(curl -L "$INSTALLER_URL" 2>/dev/null | grep INSTALLER_DATA= 2>/dev/null | sed -E 's|^.*INSTALLER_DATA=(.*)$|\1|' 2>/dev/null)"
[ -n "$INSTALLER_DATA_LINK" ] || exit_error "empty installer data link"
PACKAGE_URL="$(curl -L "$INSTALLER_DATA_LINK" 2>/dev/null | jq -r ".os_list[] | select(.name == \"$IMAGE\") | .package" 2>/dev/null)"
[ -n "$PACKAGE_URL" ] || exit_error "empty package url"
case "$PACKAGE_URL" in
http*) ;;
*) PACKAGE_URL="$(echo "$INSTALLER_DATA_LINK" | rev | cut -d/ -f2- | rev)/os/$PACKAGE_URL" ;;
esac
PACKAGE="$(basename "$PACKAGE_URL" 2>/dev/null)"
mkdir images >/dev/null 2>&1 || true
[ -e "images/$PACKAGE" ] || wget -O "images/$PACKAGE" "$PACKAGE_URL" >&2
echo "images/$PACKAGE"
