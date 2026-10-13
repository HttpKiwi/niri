import QtQuick
import QtQuick.Layouts
import qs.config

ColumnLayout {
    id: root
    property string title: ""
    property string subtitle: ""
    default property alias content: body.data

    Layout.fillWidth: true
    spacing: 8

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: cardCol.implicitHeight + 28
        radius: Settings.cardRadius
        color: Theme.withAlpha(Theme.surfaceBase, 0.35)
        border.width: 1
        border.color: Theme.withAlpha(Theme.textPrimary, 0.1)

        ColumnLayout {
            id: cardCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: root.title
                    color: Theme.textPrimary
                    font.family: Settings.fontFamilyDefault
                    font.pixelSize: Settings.fontSizeLarge
                    font.weight: Font.DemiBold
                }

                Text {
                    visible: root.subtitle.length > 0
                    Layout.fillWidth: true
                    text: root.subtitle
                    color: Theme.textSecondary
                    font.family: Settings.fontFamilyDefault
                    font.pixelSize: Settings.fontSizeSmall
                    wrapMode: Text.Wrap
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.withAlpha(Theme.textPrimary, 0.08)
            }

            ColumnLayout {
                id: body
                Layout.fillWidth: true
                spacing: 12
            }
        }
    }
}
