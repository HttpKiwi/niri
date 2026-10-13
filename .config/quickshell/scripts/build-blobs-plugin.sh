#!/usr/bin/env bash
# Build the Caelestia.Blobs QML plugin and install it into qml/ (on QML_IMPORT_PATH).
# Restart quickshell afterwards: plugin libraries don't reload on soft reload.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/../plugins" && pwd)"
BUILD_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/caelestia-blobs-build"
INSTALL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/qml/Caelestia/Blobs"

cmake -S "$SOURCE_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release
cmake --build "$BUILD_DIR" -j"$(nproc)"

mkdir -p "$INSTALL_DIR"
for f in libcaelestia-blobsplugin.so libcaelestia-blobs.so qmldir caelestia-blobs.qmltypes; do
    # Copy then rename: a new inode leaves the running shell's mmapped .so intact
    cp "$BUILD_DIR/$f" "$INSTALL_DIR/.$f.new"
    mv -f "$INSTALL_DIR/.$f.new" "$INSTALL_DIR/$f"
done

echo "Installed to $INSTALL_DIR — restart quickshell to load it."
