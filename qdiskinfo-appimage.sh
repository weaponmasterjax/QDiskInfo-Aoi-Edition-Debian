#!/bin/sh

set -eu

export ARCH="$(uname -m)"
export APPIMAGE_EXTRACT_AND_RUN=1
export QT_STYLE_OVERRIDE=Breeze

APP=QDiskInfo
APPIMAGETOOL="https://github.com/pkgforge-dev/appimagetool-uruntime/releases/download/continuous/appimagetool-$ARCH.AppImage"
UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*-$ARCH.AppImage.zsync"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
VERSION="${VERSION:-$(echo "${GITHUB_SHA:-dev}" | cut -c 1-9)-debian13}"

DEB_ARCH="$(dpkg-architecture -qDEB_HOST_MULTIARCH)"
QT6_PLUGINS="/usr/lib/${DEB_ARCH}/qt6/plugins"

# Prepare AppDir
mkdir -p ./AppDir/shared/bin
cp -v ./dist/QDiskInfo.desktop      ./AppDir
cp -v ./dist/QDiskInfo-256x256.png  ./AppDir/QDiskInfo.png
cp -v ./dist/QDiskInfo-256x256.png  ./AppDir/.DirIcon
cp -v ./build/QDiskInfo             ./AppDir/shared/bin

# Copy any theme/data files if present in the repo
for d in themes styles data resources; do
    if [ -d "./$d" ]; then
        cp -rv "./$d" ./AppDir/
    fi
done

cd ./AppDir

# Collect all existing Qt6 plugins (platforms, wayland, styles, imageformats, iconengines, etc.)
PLUGIN_LIST=""
for sub in iconengines imageformats platforms platformthemes styles xcbglintegrations wayland-decoration-client wayland-graphics-integration-client wayland-shell-integration; do
    if [ -d "$QT6_PLUGINS/$sub" ]; then
        PLUGIN_LIST="$PLUGIN_LIST $QT6_PLUGINS/$sub/*"
    fi
done

wget "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
# shellcheck disable=SC2086
./lib4bin -p -v -s -k \
	./shared/bin/QDiskInfo \
	$PLUGIN_LIST

# Bundle smartctl
./lib4bin -s --with-wrappe "$(command -v smartctl)"

# Prepare AppRun with explicit QT_PLUGIN_PATH and Breeze/Aoi theme support
cat << 'EOF' > ./AppRun
#!/bin/sh
CURRENTDIR="$(dirname "$(readlink -f "$0")")"
CACHEDIR="${XDG_CACHE_HOME:-$HOME/.cache}"

export QT_PLUGIN_PATH="$CURRENTDIR/shared/lib/qt6/plugins"
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland;xcb}"
export QT_STYLE_OVERRIDE="${QT_STYLE_OVERRIDE:-Breeze}"
export QDISKINFO_THEME_DIR="$CURRENTDIR/themes"

[ -f "$APPIMAGE".stylesheet ] && APPIMAGE_QT_THEME="$APPIMAGE.stylesheet"
[ -f "$APPIMAGE_QT_THEME" ] && set -- "$@" "-stylesheet" "$APPIMAGE_QT_THEME"

export PATH="$CACHEDIR/qdiskinfo-appimage:$PATH"
mkdir -p "$CACHEDIR"/qdiskinfo-appimage
cp -f "$CURRENTDIR"/smartctl "$CACHEDIR"/qdiskinfo-appimage/
chmod +x "$CACHEDIR"/qdiskinfo-appimage/smartctl

exec "$CURRENTDIR"/bin/QDiskInfo "$@"
EOF
chmod +x ./AppRun
./sharun -g

# Make AppImage with uruntime
cd ..
wget "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool

./appimagetool --no-appstream -u "$UPINFO" \
	"$PWD"/AppDir "$PWD"/"$APP"-"$VERSION"-"$ARCH".AppImage
