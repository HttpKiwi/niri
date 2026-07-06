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
    readonly property real closedSlide: slideFrom === "left" ? -(width + 5) : (width + 5)
    property real slideX: closedSlide

    readonly property real visualX: x + slideX
    readonly property real visualY: y
    readonly property real visualW: width
    readonly property real visualH: height
    readonly property bool pocketActive: slideFrom === "left"
        ? slideX > closedSlide
        : slideX < closedSlide

    visible: pocketActive

    signal opened()
    signal closed()

    default property alias content: contentHost.data

    transform: Translate {
        x: root.slideX
    }

    Behavior on slideX {
        NumberAnimation {
            duration: root.slideDuration
            easing.type: Settings.easingStandard
        }
    }

    function openPanel() {
        slideX = 0;
        opened();
    }

    function closePanel() {
        slideX = closedSlide;
        closed();
    }

    onShouldBeActiveChanged: {
        if (shouldBeActive)
            openPanel();
        else
            closePanel();
    }

    Component.onCompleted: {
        slideX = shouldBeActive ? 0 : closedSlide;
        if (shouldBeActive)
            opened();
    }

    Item {
        id: contentHost
        anchors.fill: parent
    }
}
