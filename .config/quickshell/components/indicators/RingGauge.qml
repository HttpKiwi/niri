import QtQuick
import QtQuick.Shapes
import qs.config

/**
 * RingGauge - 80% ring (gap at the bottom) with an icon in the middle.
 * Hover swaps the icon for the percentage.
 */
Item {
    id: root

    // 0..1
    property real value: 0
    // Material Symbols ligature, e.g. "memory"
    property string icon: ""
    property real warnAt: 0.85
    property int size: Settings.barPillHeight
    property real thickness: 2.2

    // 288° sweep, 72° gap centred on the bottom (Qt angles: 0° = 3 o'clock, clockwise)
    readonly property real sweep: 288
    readonly property real startAngle: 90 + (360 - sweep) / 2
    readonly property real clamped: Math.max(0, Math.min(1, value))
    readonly property color ringColor: clamped >= warnAt ? Theme.error : Theme.accent

    implicitWidth: size
    implicitHeight: size

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // Track
        ShapePath {
            fillColor: "transparent"
            strokeColor: Theme.withAlpha(Theme.textPrimary, 0.18)
            strokeWidth: root.thickness
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: (root.size - root.thickness) / 2
                radiusY: radiusX
                startAngle: root.startAngle
                sweepAngle: root.sweep
            }
        }

        // Value
        ShapePath {
            fillColor: "transparent"
            strokeColor: root.ringColor
            strokeWidth: root.thickness
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: (root.size - root.thickness) / 2
                radiusY: radiusX
                startAngle: root.startAngle
                sweepAngle: Math.max(0.01, root.sweep * root.clamped)

                Behavior on sweepAngle {
                    NumberAnimation { duration: Settings.animationDurationMedium; easing.type: Easing.OutCubic }
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: hover.containsMouse ? Math.round(root.clamped * 100) : root.icon
        color: Theme.textPrimary
        font.family: hover.containsMouse ? Settings.fontFamilyDefault : Settings.fontFamilyIcons
        font.pixelSize: hover.containsMouse ? 7 : Math.round(root.size * 0.58)
        font.weight: hover.containsMouse ? Font.DemiBold : Font.Normal
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
    }
}
