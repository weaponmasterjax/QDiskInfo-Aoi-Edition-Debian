#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"

BUILD_DIR="$REPO_ROOT/build"
OUTPUT_DIR="$REPO_ROOT"
DEB_VERSION="${DEB_VERSION:-}"
DEB_RELEASE="${DEB_RELEASE:-1}"
SKIP_BUILD=0
FETCH_THEMES=0
REQUIRE_THEMES=0

usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

Options:
  --build-dir <dir>    CMake build directory (default: \$REPO_ROOT/build)
  --output-dir <dir>   Output directory for generated .deb (default: \$REPO_ROOT)
  --version <ver>      Override Debian upstream version (env: DEB_VERSION)
  --release <rel>      Override Debian package revision (default: 1, env: DEB_RELEASE)
  --skip-build         Skip CMake configure/build and package existing build dir
  --fetch-themes       Run scripts/fetch-aoi-themes.sh if Aoi themes are missing
  --require-themes     Require Aoi themes to exist and be included in the .deb
  -h, --help           Show this help message
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --build-dir)
            [ "$#" -ge 2 ] || { echo "Error: --build-dir requires an argument" >&2; exit 1; }
            BUILD_DIR="$2"
            shift 2
            ;;
        --build-dir=*)
            BUILD_DIR="${1#*=}"
            shift
            ;;
        --output-dir)
            [ "$#" -ge 2 ] || { echo "Error: --output-dir requires an argument" >&2; exit 1; }
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --output-dir=*)
            OUTPUT_DIR="${1#*=}"
            shift
            ;;
        --version)
            [ "$#" -ge 2 ] || { echo "Error: --version requires an argument" >&2; exit 1; }
            DEB_VERSION="$2"
            shift 2
            ;;
        --version=*)
            DEB_VERSION="${1#*=}"
            shift
            ;;
        --release)
            [ "$#" -ge 2 ] || { echo "Error: --release requires an argument" >&2; exit 1; }
            DEB_RELEASE="$2"
            shift 2
            ;;
        --release=*)
            DEB_RELEASE="${1#*=}"
            shift
            ;;
        --skip-build)
            SKIP_BUILD=1
            shift
            ;;
        --fetch-themes)
            FETCH_THEMES=1
            shift
            ;;
        --require-themes)
            REQUIRE_THEMES=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Error: Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

for cmd in cpack dpkg-deb dpkg-shlibdeps file; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: Required command not found: $cmd" >&2
        exit 1
    fi
done

if [ "$SKIP_BUILD" -eq 0 ] && ! command -v cmake >/dev/null 2>&1; then
    echo "Error: Required command not found: cmake" >&2
    exit 1
fi

if [ -n "$DEB_VERSION" ]; then
    if ! printf '%s\n' "$DEB_VERSION" | grep -Eq '^[0-9][A-Za-z0-9.+~]*$'; then
        echo "Error: Invalid Debian upstream version '$DEB_VERSION' (must match ^[0-9][A-Za-z0-9.+~]*$)" >&2
        exit 1
    fi
fi

if ! printf '%s\n' "$DEB_RELEASE" | grep -Eq '^[A-Za-z0-9.+~]+$'; then
    echo "Error: Invalid Debian revision '$DEB_RELEASE' (must match ^[A-Za-z0-9.+~]+$)" >&2
    exit 1
fi

if [ "$FETCH_THEMES" -eq 1 ] && [ ! -f "$REPO_ROOT/themes/Aoi/AoiBackground-300.png" ]; then
    (cd "$REPO_ROOT" && "$REPO_ROOT/scripts/fetch-aoi-themes.sh")
fi

if [ "$REQUIRE_THEMES" -eq 1 ]; then
    if [ ! -f "$REPO_ROOT/themes/Aoi/AoiBackground-300.png" ] || [ ! -f "$REPO_ROOT/themes/Aoi/SDdiskStatusGood100-300.png" ]; then
        echo "Error: Required Aoi themes missing under $REPO_ROOT/themes/Aoi/" >&2
        exit 1
    fi
fi

if [ "$SKIP_BUILD" -eq 0 ]; then
    JOBS="$(nproc 2>/dev/null || echo 2)"
    cmake -S "$REPO_ROOT" -B "$BUILD_DIR" \
        -DCMAKE_BUILD_TYPE="${BUILD_TYPE:-MinSizeRel}" \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DQT_VERSION_MAJOR="${QT_VERSION_MAJOR:-6}" \
        -DENABLE_TRANSLATIONS="${ENABLE_TRANSLATIONS:-ON}" \
        -DINCLUDE_OPTIONAL_RESOURCES="${INCLUDE_OPTIONAL_RESOURCES:-ON}" \
        -DCHARACTER_IS_RIGHT="${CHARACTER_IS_RIGHT:-ON}"
    cmake --build "$BUILD_DIR" --parallel "$JOBS"
fi

if [ ! -f "$BUILD_DIR/CPackConfig.cmake" ]; then
    echo "Error: Missing $BUILD_DIR/CPackConfig.cmake; run cmake first or omit --skip-build" >&2
    exit 1
fi

CPACK_STAGE_DIR="$BUILD_DIR/cpack-deb"
rm -rf "$CPACK_STAGE_DIR"
mkdir -p "$CPACK_STAGE_DIR" "$OUTPUT_DIR"

if [ -n "$DEB_VERSION" ]; then
    cpack --config "$BUILD_DIR/CPackConfig.cmake" \
        -G DEB \
        -B "$CPACK_STAGE_DIR" \
        -D "CPACK_PACKAGE_VERSION=$DEB_VERSION" \
        -D "CPACK_DEBIAN_PACKAGE_RELEASE=$DEB_RELEASE"
else
    cpack --config "$BUILD_DIR/CPackConfig.cmake" \
        -G DEB \
        -B "$CPACK_STAGE_DIR" \
        -D "CPACK_DEBIAN_PACKAGE_RELEASE=$DEB_RELEASE"
fi

DEB_COUNT=0
DEB_FILE=""
for f in "$CPACK_STAGE_DIR"/*.deb; do
    if [ -f "$f" ]; then
        DEB_COUNT=$((DEB_COUNT + 1))
        DEB_FILE="$f"
    fi
done

if [ "$DEB_COUNT" -ne 1 ]; then
    echo "Error: Expected exactly 1 .deb file in $CPACK_STAGE_DIR, found $DEB_COUNT" >&2
    exit 1
fi

OUT_DEB="$OUTPUT_DIR/$(basename "$DEB_FILE")"
cp -f "$DEB_FILE" "$OUT_DEB"

dpkg-deb --info "$OUT_DEB"
DEB_CONTENTS="$(dpkg-deb --contents "$OUT_DEB")"

check_deb_path() {
    if ! printf '%s\n' "$DEB_CONTENTS" | grep -Eq "(^|[[:space:]])\.?$1$"; then
        echo "Error: Expected file missing from .deb archive: $1" >&2
        exit 1
    fi
}

check_deb_path "/usr/bin/QDiskInfo"
check_deb_path "/usr/share/applications/QDiskInfo\.desktop"
check_deb_path "/usr/share/icons/hicolor/scalable/apps/QDiskInfo\.svg"
check_deb_path "/usr/share/icons/hicolor/256x256/apps/QDiskInfo\.png"
check_deb_path "/usr/share/doc/qdiskinfo-aoi/copyright"

if [ "$REQUIRE_THEMES" -eq 1 ]; then
    check_deb_path "/usr/share/QDiskInfo/themes/Aoi/AoiBackground-300\.png"
    check_deb_path "/usr/share/QDiskInfo/themes/Aoi/SDdiskStatusGood100-300\.png"
fi

DEB_DEPENDS="$(dpkg-deb --field "$OUT_DEB" Depends)"
for dep in smartmontools pkexec qt6-wayland libc6; do
    if ! printf '%s\n' "$DEB_DEPENDS" | grep -q "$dep"; then
        echo "Error: Expected dependency missing from Depends: $dep ($DEB_DEPENDS)" >&2
        exit 1
    fi
done

echo "Built and verified .deb package: $OUT_DEB"
