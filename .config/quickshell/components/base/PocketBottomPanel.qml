pragma ComponentBehavior: Bound

import QtQuick
import qs.config

/**
 * PocketBottomPanel - Bottom emerge animation for bar pockets.
 * Uses translateY (not bottomMargin) so height stays stable during hide — blob tracks visualY/visualH.
 */
Item {
    id: root

    required property var panelState
    required property string panelFlag
    property int bottomInset: 5
    property int animationDuration: Settings.animationDurationShort
    property int easingType: Easing.OutCubic

    readonly property bool shouldBeActive: panelState && panelState[panelFlag]

    property real _hideTravel: 0
    property real slideOffset: 0
    property bool animatingHide: false

    readonly property bool pocketActive: shouldBeActive || animatingHide

    // Layout position (ignores translate) — for blob that collapses into the bottom frame edge
    readonly property real hideProgress: _hideTravel > 0 ? Math.min(1, slideOffset / _hideTravel) : 0
    readonly property real blobX: x
    readonly property real blobY: y + height * hideProgress
    readonly property real blobW: width
    readonly property real blobH: pocketActive ? height * (1 - hideProgress) : 0

    // Translated bounds — for hit testing / overlays
    readonly property real visualX: x
    readonly property real visualY: y + slideOffset
    readonly property real visualW: width
    readonly property real visualH: height

    visible: pocketActive
    opacity: _hideTravel > 0 ? Math.max(0, 1 - slideOffset / _hideTravel) : (shouldBeActive ? 1 : 0)

    signal opened()
    signal closed()

    default property alias content: contentHost.data

    transform: Translate {
        y: root.slideOffset
    }

    Behavior on slideOffset {
        NumberAnimation {
            duration: root.animationDuration
            easing.type: root.easingType
            onStopped: {
                if (root.animatingHide) {
                    root.animatingHide = false;
                    root.slideOffset = 0;
                    root._hideTravel = 0;
                    root.closed();
                }
            }
        }
    }

    onShouldBeActiveChanged: {
        if (shouldBeActive)
            beginShow();
        else
            beginHide();
    }

    function hideTravel() {
        return implicitHeight + bottomInset;
    }

    function beginShow() {
        animatingHide = false;
        _hideTravel = hideTravel();
        if (_hideTravel <= 0) {
            slideOffset = 0;
            opened();
            return;
        }
        slideOffset = _hideTravel;
        Qt.callLater(() => slideOffset = 0);
        opened();
    }

    function beginHide() {
        if (animatingHide)
            return;
        _hideTravel = hideTravel();
        if (_hideTravel <= 0) {
            closed();
            return;
        }
        animatingHide = true;
        slideOffset = _hideTravel;
    }

    Item {
        id: contentHost
        anchors.fill: parent
    }
}
