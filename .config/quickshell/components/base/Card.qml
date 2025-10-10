import QtQuick
import qs.config

/**
 * Card - Reusable floating card component
 * Base component for all elevated surfaces (notifications, OSD, etc.)
 */
Rectangle {
    id: root
    
    // Elevation level (0-4)
    property int elevation: 3
    
    // Border visibility
    property bool showBorder: false
    
    // Content padding
    property int contentPadding: Settings.cardPadding
    
    // Apply theme colors based on elevation
    color: Theme.surfaceBase
    radius: Settings.cardRadius
    border.color: showBorder ? Theme.cardBorder : "transparent"
    border.width: showBorder ? Settings.cardBorderWidth : 0
    
    // Default content item for easy composition
    default property alias contentItem: contentContainer.data
    
    Item {
        id: contentContainer
        anchors.fill: parent
        anchors.margins: root.contentPadding
    }
}
