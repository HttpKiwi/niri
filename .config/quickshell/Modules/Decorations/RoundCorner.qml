import QtQuick
import QtQuick.Shapes
import Quickshell

Item {
    id: root

    property int size: 32
    property color color: "#000000"
    
    property QtObject cornerEnum: QtObject {
        readonly property int topLeft: 0
        readonly property int topRight: 1
        readonly property int bottomLeft: 2
        readonly property int bottomRight: 3
    }

    property int corner: topLeft // Default to TopLeft

    // Internal property to calculate rotation angle based on corner
    property real rotationAngle: {
        switch (corner) {
        case cornerEnum.topLeft:
            return 90
        case cornerEnum.topRight:
            return 180
        case cornerEnum.bottomRight:
            return 270
        case cornerEnum.bottomLeft:
            return 0
        default:
            return 0
        }
    }

    width: size
    height: size

    Shape {
        id: shape
        asynchronous: true
        fillMode: Shape.PreserveAspectFit
        preferredRendererType: Shape.CurveRenderer
        anchors.fill: parent

        ShapePath {
            startX: 0
            startY: 0
            strokeWidth: -1
            fillColor: root.color

            PathLine { x: 0; y: root.height }
            PathLine { x: root.width; y: root.height }
            PathArc { 
                x: 0
                y: 0
                radiusX: root.size
                radiusY: root.size
            }
        }

        transform: Rotation {
            origin.x: shape.width / 2
            origin.y: shape.height / 2
            angle: root.rotationAngle
        }
    }
}