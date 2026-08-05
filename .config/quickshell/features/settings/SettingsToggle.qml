import QtQuick
import QtQuick.Layouts
import qs.config

RowLayout {
    id: root
    property string label: ""
    property string description: ""
    property bool checked: false
    signal toggled(bool value)

    Layout.fillWidth: true
    spacing: 12

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        Text {
            text: root.label
            color: Theme.textPrimary
            font.family: Settings.fontFamilyDefault
            font.pixelSize: Settings.fontSizeMedium
        }
        Text {
            visible: root.description.length > 0
            Layout.fillWidth: true
            text: root.description
            color: Theme.textSecondary
            font.family: Settings.fontFamilyDefault
            font.pixelSize: Settings.fontSizeCaption
            wrapMode: Text.Wrap
        }
    }

    Rectangle {
        Layout.preferredWidth: 44
        Layout.preferredHeight: 24
        radius: 12
        color: root.checked ? Theme.withAlpha(Theme.accent, 0.55) : Theme.withAlpha(Theme.textPrimary, 0.12)

        Rectangle {
            width: 18
            height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 3 : 3
            color: root.checked ? Theme.textOnPrimary : Theme.textPrimary
            Behavior on x { NumberAnimation { duration: Settings.animationDurationShort } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled(!root.checked)
        }
    }
}
