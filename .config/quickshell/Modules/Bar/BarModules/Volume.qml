import QtQuick
import Quickshell.Io
import Quickshell.Widgets
import Services 1.0

WrapperMouseArea {
    onClicked: {
        console.log("Volume clicked");
        Audio.setVolume(0);
    }
    hoverEnabled: true
    onEntered: {
        text.color = "yellow";
        volume.opacity = 1;
        volume.width = text.width + 10;
    }
    onExited: {
        volume.opacity = 0;
        text.color = "white";
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
        spacing: 0

        Text {
            id: text

            topPadding: 2
            fontSizeMode: Text.VerticalFit
            font.family: "Material Symbols"
            color: "white"
            font.pixelSize: 14
            text: "\ue050 "
        }

        Text {
            id: volume

            anchors.verticalCenter: parent.verticalCenter
            opacity: 0
            width: 0
            fontSizeMode: Text.VerticalFit
            font.family: "Material Symbols"
            color: "white"
            font.pixelSize: 12
            text: Audio.volume.toFixed(2) * 100 + "%"

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
