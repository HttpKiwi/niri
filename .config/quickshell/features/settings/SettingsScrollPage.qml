import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config

/**
 * SettingsScrollPage - Shared Flickable + scrollbar gutter for settings pages
 */
Flickable {
    id: root

    default property alias content: col.data
    property int spacing: 22
    readonly property int scrollGutter: 16

    clip: true
    pressDelay: 80
    boundsBehavior: Flickable.StopAtBounds
    contentWidth: Math.max(width - scrollGutter, 1)
    contentHeight: col.implicitHeight

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        implicitWidth: 10
        padding: 2
    }

    ColumnLayout {
        id: col
        width: Math.max(root.width - root.scrollGutter, 1)
        spacing: root.spacing
    }
}
