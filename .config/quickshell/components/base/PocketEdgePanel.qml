pragma ComponentBehavior: Bound

import QtQuick
import qs.config

/**
 * PocketEdgePanel - Vertical emerge for bar pockets (top or bottom).
 * Snaps off-screen before enter so the first frame never fully-open-pops.
 */
Item {
    id: root

    required property var panelState
    required property string panelFlag
    // "top" | "bottom"
    property string edge: "bottom"
    property int edgeInset: 5
    // Compat aliases used by existing panels
    property alias topInset: root.edgeInset
    property alias bottomInset: root.edgeInset

    property int animationDuration: Settings.animationDurationShort
    property int easingType: Easing.OutCubic

    readonly property bool shouldBeActive: panelState && panelState[panelFlag]
    readonly property bool fromTop: edge === "top"

    property real _hideTravel: 0
    property real slideOffset: 0
    property bool animatingHide: false
    property bool _entering: false

    readonly property bool pocketActive: shouldBeActive || animatingHide || _entering

    readonly property real hideProgress: {
        if (_hideTravel <= 0)
            return 0;
        const raw = fromTop ? -slideOffset : slideOffset;
        return Math.min(1, Math.max(0, raw / _hideTravel));
    }

    readonly property real blobX: x
    readonly property real blobY: fromTop ? y : (y + height * hideProgress)
    readonly property real blobW: width
    readonly property real blobH: pocketActive ? height * (1 - hideProgress) : 0

    readonly property real visualX: x
    readonly property real visualY: y + slideOffset
    readonly property real visualW: width
    readonly property real visualH: height

    visible: pocketActive
    opacity: {
        if (!pocketActive)
            return 0;
        if (_hideTravel > 0)
            return Math.max(0, 1 - hideProgress);
        return shouldBeActive ? 1 : 0;
    }

    signal opened()
    signal closed()

    default property alias content: contentHost.data

    transform: Translate {
        y: root.slideOffset
    }

    Behavior on slideOffset {
        id: slideBehavior
        enabled: true
        NumberAnimation {
            duration: root.animationDuration
            easing.type: root.easingType
            onStopped: {
                if (root.animatingHide) {
                    root.animatingHide = false;
                    root.closed();
                } else if (root._entering) {
                    root._entering = false;
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
        return Math.max(implicitHeight, height, 0) + edgeInset;
    }

    function _offscreenOffset(travel) {
        return fromTop ? -travel : travel;
    }

    function _snapOffscreen(travel) {
        slideBehavior.enabled = false;
        _hideTravel = travel;
        slideOffset = _offscreenOffset(travel);
        slideBehavior.enabled = true;
    }

    function beginShow() {
        animatingHide = false;
        _entering = true;
        const guess = Math.max(hideTravel(), 48);
        _snapOffscreen(guess);
        opened();
        Qt.callLater(() => {
            if (!root.shouldBeActive)
                return;
            const travel = Math.max(root.hideTravel(), 48);
            root._snapOffscreen(travel);
            root.slideOffset = 0;
        });
    }

    function beginHide() {
        if (animatingHide)
            return;
        _entering = false;
        const travel = Math.max(hideTravel(), Math.abs(slideOffset), 48);
        _hideTravel = travel;
        if (travel <= 0) {
            closed();
            return;
        }
        animatingHide = true;
        slideOffset = _offscreenOffset(travel);
    }

    Item {
        id: contentHost
        anchors.fill: parent
    }
}
