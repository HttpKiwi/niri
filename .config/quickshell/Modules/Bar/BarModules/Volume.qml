import QtQuick
import Quickshell.Widgets
import Services 1.0

WrapperMouseArea {
    onClicked: {
        Audio.toggleMute();
    }
    hoverEnabled: true
    onEntered: {
        text.color = Color.on_surface;
        volume.opacity = 1;
        volume.width = text.width + 10;
    }
    onExited: {
        volume.opacity = 0;
        text.color = Color.on_surface;
        volume.width = 0;
    }
    scrollGestureEnabled: true
    onWheel: {
        if (wheel.angleDelta.y > 0)
            Audio.raiseVolume();
        else
            Audio.lowerVolume();
    }

    Row {
        height: text.height
        spacing: 4

        Text {
            id: text

            topPadding: 2
            fontSizeMode: Text.VerticalFit
            font.family: "Material Symbols"
            color: Color.on_surface
            font.pixelSize: 14
            text: Audio.muted ? "\ue04f" : "\ue050"
        }

        Text {
            id: volume

            anchors.verticalCenter: parent.verticalCenter
            opacity: 0
            width: 0
            fontSizeMode: Text.VerticalFit
            font.family: "Material Symbols"
            color: Color.on_surface
            font.pixelSize: 12
            text: Audio.getVolume() + "%"

            Behavior on width {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.InOutQuad
                }

            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.InOutQuad
                }

            }

        }

    }

}
