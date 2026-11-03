#!/bin/bash
# Builds the Ubuntu/Debian package for Grid Map Editor.
#
# Requirements (build machine only): python3 with venv, dpkg-deb.
# The package runs on Ubuntu versions with the same or a newer glibc than the build
# machine; the GitHub workflow builds on Ubuntu 22.04 so it works on 22.04 and newer.
#
# Usage:  linux/build_deb.sh [version]     (default: __version__ in src/grid_map_editor/__init__.py)
#         PYTHON=python3.12 linux/build_deb.sh
# Output: dist-installer/grid-map-editor_<version>_amd64.deb
# Install: sudo apt install ./dist-installer/grid-map-editor_<version>_amd64.deb
set -e

LINUX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$LINUX_DIR")"
BUILD="$ROOT/build"
VENV="$BUILD/venv-linux"
PYTHON="${PYTHON:-python3}"
PKG="grid-map-editor"

VERSION="${1:-$(sed -n 's/^__version__ = "\(.*\)"/\1/p' "$ROOT/src/grid_map_editor/__init__.py")}"
[ -n "$VERSION" ] || { echo "Version not found"; exit 1; }

echo "=== 1/3 Preparing Python build environment"
[ -x "$VENV/bin/python" ] || "$PYTHON" -m venv "$VENV"
"$VENV/bin/python" -m pip install --upgrade pip
"$VENV/bin/python" -m pip install -r "$LINUX_DIR/requirements-linux.txt"

echo "=== 2/3 Bundling with PyInstaller"
"$VENV/bin/python" -m PyInstaller "$ROOT/OccupancyGridMapEditor.spec" --noconfirm --clean \
    --distpath "$BUILD/pyinstaller-linux/dist" --workpath "$BUILD/pyinstaller-linux/work"

echo "=== 3/3 Creating .deb package"
STAGE="$BUILD/deb/${PKG}_${VERSION}_amd64"
rm -rf "$STAGE"
mkdir -p "$STAGE/DEBIAN" "$STAGE/opt" "$STAGE/usr/bin" "$STAGE/usr/share/applications"
cp -a "$BUILD/pyinstaller-linux/dist/GridMapEditor" "$STAGE/opt/$PKG"
ln -s "/opt/$PKG/GridMapEditor" "$STAGE/usr/bin/$PKG"
cp "$LINUX_DIR/$PKG.desktop" "$STAGE/usr/share/applications/"
for size in 48 128 256 512; do
    mkdir -p "$STAGE/usr/share/icons/hicolor/${size}x${size}/apps"
    "$VENV/bin/python" -c "import sys; from PIL import Image; Image.open(sys.argv[1]).convert('RGBA').resize((int(sys.argv[3]),) * 2, Image.LANCZOS).save(sys.argv[2])" \
        "$ROOT/src/grid_map_editor/resources/images/icon_sq1.png" \
        "$STAGE/usr/share/icons/hicolor/${size}x${size}/apps/$PKG.png" "$size"
done

# Standard package permissions (755 dirs/executables, 644 files) regardless of the build umask
chmod -R u=rwX,go=rX "$STAGE"

# Qt's X11 platform plugin needs these system libraries (not on every Ubuntu by default)
cat > "$STAGE/DEBIAN/control" << EOF
Package: $PKG
Version: $VERSION
Architecture: amd64
Maintainer: mhtayebzadeh <mhtayebzadeh@yahoo.com>
Installed-Size: $(du -sk "$STAGE" | cut -f1)
Depends: libxcb-cursor0, libxkbcommon-x11-0, libxcb-icccm4, libxcb-image0, libxcb-keysyms1, libxcb-randr0, libxcb-render-util0, libxcb-shape0, libxcb-xinerama0, libxcb-xkb1, libegl1, libgl1, libfontconfig1, libdbus-1-3
Section: graphics
Priority: optional
Homepage: https://github.com/mhtayebzadeh/grid-map-editor-py-qt
Description: Occupancy grid map editor (PGM/YAML) for ROS 2 robots
 Interactive editor for robot occupancy grid maps: edit obstacles, free and
 unknown areas, keepout layers and gates. Works with and without a GPU.
EOF

mkdir -p "$ROOT/dist-installer"
dpkg-deb --root-owner-group -Zxz --build "$STAGE" "$ROOT/dist-installer/${PKG}_${VERSION}_amd64.deb"
echo ""
echo "Done: $ROOT/dist-installer/${PKG}_${VERSION}_amd64.deb"
echo "Install with: sudo apt install ./dist-installer/${PKG}_${VERSION}_amd64.deb"
