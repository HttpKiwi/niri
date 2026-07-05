import QtQuick
import Quickshell
import Quickshell.Wayland

Item {
    id: root

    visible: false

    required property var targetWindow
    property bool blurEnabled: true
    property real blurX: 0
    property real blurY: 0
    property real blurWidth: 0
    property real blurHeight: 0
    property real blurRadius: 0
    property var region: null

    readonly property bool _active: blurEnabled
        && !!targetWindow
        && (region !== null || (blurWidth > 0 && blurHeight > 0))

    readonly property var _effectiveRegion: region !== null ? region : blurRegion

    Region {
        id: blurRegion
        x: root.blurX
        y: root.blurY
        width: root.blurWidth
        height: root.blurHeight
        radius: root.blurRadius
    }

    function _apply() {
        if (!targetWindow)
            return
        targetWindow.BackgroundEffect.blurRegion = _active ? _effectiveRegion : null
    }

    function clear() {
        if (!targetWindow)
            return
        targetWindow.BackgroundEffect.blurRegion = null
    }

    function kick() {
        clear()
        if (_active)
            targetWindow.BackgroundEffect.blurRegion = _effectiveRegion
    }

    on_ActiveChanged: _apply()
    onTargetWindowChanged: _apply()
    onRegionChanged: _apply()
    onBlurXChanged: if (region === null) _apply()
    onBlurYChanged: if (region === null) _apply()
    onBlurWidthChanged: if (region === null) _apply()
    onBlurHeightChanged: if (region === null) _apply()
    onBlurRadiusChanged: if (region === null) _apply()

    Connections {
        target: root.targetWindow ?? null
        ignoreUnknownSignals: true
        function onVisibleChanged() {
            root._apply()
        }
        function onWidthChanged() {
            root._apply()
        }
        function onHeightChanged() {
            root._apply()
        }
    }

    Component.onCompleted: _apply()
    Component.onDestruction: clear()
}
