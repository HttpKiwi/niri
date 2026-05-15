#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="/home/httpkiwi/niri/.config/quickshell/plugins/build"
SOURCE_DIR="/home/httpkiwi/niri/.config/quickshell/plugins"

cmake -S "$SOURCE_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release
cmake --build "$BUILD_DIR" -j"$(nproc)"

sudo mkdir -p /usr/lib/qt6/qml/Caelestia/Blobs
sudo cp "$BUILD_DIR"/libcaelestia-blobsplugin.so /usr/lib/qt6/qml/Caelestia/Blobs/
sudo cp "$BUILD_DIR"/libcaelestia-blobs.so /usr/lib/qt6/qml/Caelestia/Blobs/
sudo cp "$BUILD_DIR"/qmldir /usr/lib/qt6/qml/Caelestia/Blobs/
sudo cp "$BUILD_DIR"/caelestia-blobs.qmltypes /usr/lib/qt6/qml/Caelestia/Blobs/

echo "Plugin built and installed."
