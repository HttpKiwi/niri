import QtQuick
import QtQuick.Shapes
import qs.config

/**
 * RingGauge - 60% ring (open at the bottom, like a dial) with an icon in the middle.
 * Hover swaps the icon for the percentage.
 */
Item {
    id: root

    // 0..1
    property real value: 0
    // Material Symbols ligature, e.g. "memory"
    property string icon: ""
    property real warnAt: 0.85
    // Leave room inside the pill so the ring never touches its border
    property int size: Settings.barPillHeight - 4
    property real thickness: 2

    // 216° sweep, 144° gap centred on the bottom (Qt angles: 0° = 3 o'clock, clockwise)
    readonly property real sweep: 216
    readonly property real startAngle: 90 + (360 - sweep) / 2
    readonly property real clamped: Math.max(0, Math.min(1, value))
    readonly property color ringColor: clamped >= warnAt ? Theme.error : Theme.accent
    // The arc's bounding box ends at r·sin(36°) below centre, so it reads
    // top-heavy; nudge ring + icon down to centre it optically in the pill
    readonly property int opticalOffset: Math.round(size * 0.1)

    implicitWidth: size
    implicitHeight: size

    Shape {
        anchors.fill: parent
        anchors.topMargin: root.opticalOffset
        anchors.bottomMargin: -root.opticalOffset
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
        anchors.verticalCenterOffset: root.opticalOffset
        text: hover.containsMouse ? Math.round(root.clamped * 100) : root.icon
        color: Theme.textPrimary
        font.family: hover.containsMouse ? Settings.fontFamilyDefault : Settings.fontFamilyIcons
        font.pixelSize: hover.containsMouse ? 7 : Math.round(root.size * 0.62)
        font.weight: hover.containsMouse ? Font.DemiBold : Font.Normal
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
    }
}
