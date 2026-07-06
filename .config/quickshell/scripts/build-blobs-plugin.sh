#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/../plugins" && pwd)"
BUILD_DIR="$SOURCE_DIR/build"

cmake -S "$SOURCE_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release
cmake --build "$BUILD_DIR" -j"$(nproc)"

sudo mkdir -p /usr/lib/qt6/qml/Caelestia/Blobs
sudo cp "$BUILD_DIR"/libcaelestia-blobsplugin.so /usr/lib/qt6/qml/Caelestia/Blobs/
sudo cp "$BUILD_DIR"/libcaelestia-blobs.so /usr/lib/qt6/qml/Caelestia/Blobs/
sudo cp "$BUILD_DIR"/qmldir /usr/lib/qt6/qml/Caelestia/Blobs/
sudo cp "$BUILD_DIR"/caelestia-blobs.qmltypes /usr/lib/qt6/qml/Caelestia/Blobs/

echo "Plugin built and installed."
