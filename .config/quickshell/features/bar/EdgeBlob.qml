import QtQuick
import Caelestia.Blobs
import qs.config

/**
 * EdgeBlob - Blob for a PocketEdgePanel (launcher, wallpaper, settings, calendar)
 */
BlobRect {
    property Item panel: null
    property real margin: 0
    // Extra height reaching into the bar so the pocket merges with the frame
    property real reach: 0
    readonly property real _h: panel ? panel.blobH : 0

    x: panel ? panel.blobX + margin : 0
    y: panel ? panel.blobY + margin - reach : 0
    width: _h > 0 ? panel.blobW : 0
    height: _h > 0 ? _h + reach : 0
    radius: Settings.screenCornerRadius
    deformScale: panel && _h > 4 && panel.hideProgress < 0.85 ? 0.00001 : 0
    stiffness: 200
    damping: 60
    visible: _h > 0
}
