#!/bin/sh
set -eu

AOI_ZIP_URL="${AOI_ZIP_URL:-https://sourceforge.net/projects/crystaldiskinfo/files/9.9.5/CrystalDiskInfo9_9_5Aoi.zip/download}"
LOCAL_ZIP="${1:-${AOI_ZIP_PATH:-}}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

if [ -n "$LOCAL_ZIP" ]; then
    if [ ! -f "$LOCAL_ZIP" ]; then
        echo "Error: Local ZIP file not found: $LOCAL_ZIP" >&2
        exit 1
    fi
    ZIP_FILE="$LOCAL_ZIP"
    echo "Using local CrystalDiskInfo Aoi archive: $ZIP_FILE"
else
    ZIP_FILE="$TMP_DIR/CrystalDiskInfo9_9_5Aoi.zip"
    echo "Downloading CrystalDiskInfo Aoi archive from: $AOI_ZIP_URL"
    if command -v curl >/dev/null 2>&1; then
        curl -fSL --retry 3 --retry-delay 5 -o "$ZIP_FILE" "$AOI_ZIP_URL"
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$ZIP_FILE" "$AOI_ZIP_URL"
    else
        echo "Error: Neither curl nor wget is available." >&2
        exit 1
    fi
fi

echo "Validating archive..."
unzip -tq "$ZIP_FILE"

mkdir -p "$TMP_DIR/extracted"
echo "Unpacking Aoi theme backgrounds, theme.ini, and status sprites..."
unzip -q -o "$ZIP_FILE" \
    'CdiResource/themes/*/AoiBackground-300.png' \
    'CdiResource/themes/*/theme.ini' \
    'CdiResource/themes/Aoi/SDdiskStatus*-300.png' \
    -d "$TMP_DIR/extracted"

rm -rf ./themes
mkdir -p ./themes
mv "$TMP_DIR/extracted/CdiResource/themes/"* ./themes/

if [ ! -f "./themes/Aoi/AoiBackground-300.png" ] || [ ! -f "./themes/Aoi/SDdiskStatusGood100-300.png" ]; then
    echo "Error: Required Aoi theme assets missing after extraction." >&2
    exit 1
fi

echo "Discovered themes:"
for theme_dir in ./themes/*; do
    if [ -d "$theme_dir" ]; then
        echo "  - $(basename "$theme_dir")"
    fi
done
