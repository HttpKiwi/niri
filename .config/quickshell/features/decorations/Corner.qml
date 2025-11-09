import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Widgets

/**
 * Corner - Rounded corner component
 * Creates a rounded corner shape that can be positioned at any corner
 * Supports all 4 corners: 0=topLeft, 1=topRight, 2=bottomRight, 3=bottomLeft
 */
WrapperItem {
    id: cornerRoot

    property int corner: 0
    property real radius: 18
    property color color: "black"

    // Set size based on radius
    implicitWidth: radius
    implicitHeight: radius
    width: radius
    height: radius

    // Rotation based on corner - applied to parent to ensure identical shapes
    rotation: {
        switch (corner) {
        case 0: return 0    // topLeft - no rotation
        case 1: return 90   // topRight
        case 2: return 180  // bottomRight
        case 3: return 270  // bottomLeft (or -90)
        default: return 0
        }
    }

    // Transform origin at center for clean rotation
    transformOrigin: Item.Center

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        antialiasing: true
        smooth: true

        ShapePath {
            strokeWidth: 0
            fillColor: cornerRoot.color
            
            // Draw standard top-left corner, rotation handles the rest
            startX: cornerRoot.radius
            startY: 0

            PathArc {
                x: 0
                y: cornerRoot.radius
                radiusX: cornerRoot.radius
                radiusY: cornerRoot.radius
                direction: PathArc.Counterclockwise
            }

            PathLine {
                x: 0
                y: 0
            }

            PathLine {
                x: cornerRoot.radius
                y: 0
            }
        }
    }
}

