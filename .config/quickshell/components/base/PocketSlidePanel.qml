pragma ComponentBehavior: Bound

import QtQuick
import qs.config

/**
 * PocketSlidePanel - Horizontal slide animation for bar pockets.
 * Bind panelFlag to a bool property on PanelState (e.g. "controlCenter", "osd").
 */
Item {
    id: root

    required property var panelState
    required property string panelFlag
    property string slideFrom: "right"
    property int slideDuration: Settings.animationDurationMedium

    readonly property bool shouldBeActive: panelState && panelState[panelFlag]
    readonly property real closedSlide: {
        const w = Math.max(width, implicitWidth, 1);
        return slideFrom === "left" ? -(w + 5) : (w + 5);
    }

    property real slideX: 0
    property bool _entering: false
    property bool animatingHide: false

    readonly property real visualX: x + slideX
    readonly property real visualY: y
    readonly property real visualW: width
    readonly property real visualH: height
    readonly property bool pocketActive: shouldBeActive || animatingHide || _entering

    visible: pocketActive
    opacity: pocketActive ? 1 : 0

    signal opened()
    signal closed()

    default property alias content: contentHost.data

    transform: Translate {
        x: root.slideX
    }

    Behavior on slideX {
        id: slideBehavior
        enabled: true
        NumberAnimation {
            duration: root.slideDuration
            easing.type: Settings.easingStandard
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

    function _snapClosed() {
        slideBehavior.enabled = false;
        slideX = closedSlide;
        slideBehavior.enabled = true;
    }

    function openPanel() {
        animatingHide = false;
        _entering = true;
        if (width <= 1) {
            Qt.callLater(() => {
                if (root.shouldBeActive)
                    root.openPanel();
            });
            return;
        }
        _snapClosed();
        opened();
        Qt.callLater(() => {
            if (!root.shouldBeActive)
                return;
            root._snapClosed();
            root.slideX = 0;
        });
    }

    function closePanel() {
        _entering = false;
        if (width <= 1) {
            _snapClosed();
            closed();
            return;
        }
        animatingHide = true;
        slideX = closedSlide;
    }

    onShouldBeActiveChanged: {
        if (shouldBeActive)
            openPanel();
        else
            closePanel();
    }

    onWidthChanged: {
        if (!shouldBeActive && !animatingHide && !_entering)
            _snapClosed();
    }

    Component.onCompleted: {
        slideBehavior.enabled = false;
        slideX = closedSlide;
        slideBehavior.enabled = true;
        if (shouldBeActive)
            openPanel();
    }

    Item {
        id: contentHost
        anchors.fill: parent
    }
}
