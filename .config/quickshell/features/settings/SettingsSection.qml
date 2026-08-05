import QtQuick
import QtQuick.Layouts
import qs.config

ColumnLayout {
    id: root
    property string title: ""
    property string subtitle: ""
    default property alias content: body.data

    Layout.fillWidth: true
    spacing: 10

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

    ColumnLayout {
        id: body
        Layout.fillWidth: true
        spacing: 12
    }
}
