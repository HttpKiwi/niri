pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.core
import qs.components.base
import qs.features.notifications

/**
 * NotificationHistoryPanel - Main notification history panel
 * Displays grouped notification history with IPC toggle support
 */
PanelWindow {
    id: historyPanel

    property bool _showAnimation: false
    property bool _isHiding: false  // Track if we're in the process of hiding
    property bool _completingHide: false  // Track if we're completing a hide (prevent re-animation)
    property var groupedNotifications: []
    property int panelContentHeight: 600
    property int actualContentHeight: 400  // Actual height based on expanded/collapsed state
    readonly property int sidebarWidth: 420  // Windows-style sidebar width
    
    // Keyboard navigation state
    property int selectedGroupIndex: -1
    property int selectedNotificationIndex: -1
    property bool isGroupSelected: true  // true = group selected, false = notification selected

    visible: false
    implicitWidth: sidebarWidth
    // Height will be determined by anchors (top to bottom with margins)
    // Using a large fixed height to avoid PanelWindow animation
    implicitHeight: (historyPanel.screen?.height || 1080) - 56  // Screen height minus top/bottom margins
    color: "transparent"
    exclusiveZone: -1

    // Position as floating sidebar on the right (Windows-style)
    anchors {
        top: true
        bottom: true
        right: true
    }

    margins {
        top: 40  // Below the bar
        bottom: 16
        right: 16  // Small margin from right edge
    }

    // Mask for smooth animations (required for transparent+mask pattern)
    mask: Region {
        item: container
    }

    Component.onCompleted: {
        WlrLayershell.layer = WlrLayer.Overlay
        WlrLayershell.namespace = "quickshell-notification-history"
        updateNotifications()
    }

    // Listen to NotificationStore changes
    Connections {
        target: NotificationStore
        function onNotificationsChanged() {
            updateNotifications()
        }
    }

    function updateNotifications() {
        groupedNotifications = NotificationStore.getGroupedNotifications()
        Qt.callLater(() => updateContentHeight())
    }
    
    function updateContentHeight() {
        let totalHeight = 0
        const headerHeight = 60  // Header row height
        const groupHeaderHeight = 60  // Each group header height
        const notificationItemHeight = 84  // Each notification item height (updated to match ListView calculation)
        const groupSpacing = 12
        
        totalHeight += headerHeight + 20  // Header + padding
        
        // Calculate height based on groupedNotifications data instead of iterating children
        // This is more efficient and avoids creating QML objects just for height calculation
        for (let i = 0; i < groupedNotifications.length; i++) {
            const group = groupedNotifications[i]
            totalHeight += groupHeaderHeight
            
            // Check if group is expanded by finding the component
            let isExpanded = true  // Default to expanded
            for (let j = 0; j < groupsColumn.children.length; j++) {
                const child = groupsColumn.children[j]
                if (child && child.objectName === "notificationGroup" + i) {
                    isExpanded = child.expanded || false
                    break
                }
            }
            
            if (isExpanded && group.notifications && group.notifications.length > 0) {
                // Add height for expanded notifications (capped at reasonable max)
                totalHeight += Math.min(group.notifications.length * notificationItemHeight, 600)
            }
            
            if (i < groupedNotifications.length - 1) {
                totalHeight += groupSpacing
            }
        }
        
        actualContentHeight = Math.max(200, Math.min(600, totalHeight))
        panelContentHeight = actualContentHeight
    }

    onVisibleChanged: {
        if (visible) {
            // Only reset if we're not in the middle of a hide animation
            if (!_isHiding) {
                // Cancel any pending hide
                hideAnimationTimer.stop()
                updateNotifications()
                WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive
                _showAnimation = false
                // Reset selection
                selectedGroupIndex = groupedNotifications.length > 0 ? 0 : -1
                selectedNotificationIndex = -1
                isGroupSelected = true
                // Force focus to receive keyboard events
                container.forceActiveFocus()
                Qt.callLater(() => {
                    _showAnimation = true
                    // Ensure focus is maintained
                    container.forceActiveFocus()
                })
            }
            // If _isHiding is true, we're re-showing for animation, so don't reset
        } else {
            // When visible becomes false, start hide animation if not already hiding
            // and if we're not completing a hide (timer is handling final hide)
            if (!_isHiding && !_completingHide) {
                // Re-show panel to allow animation to play (use callLater to avoid recursion)
                Qt.callLater(() => {
                    if (!visible && !_isHiding && !_completingHide) {  // Only if still supposed to be hidden
                        _isHiding = true
                        _showAnimation = false
                        visible = true  // Keep visible for animation
                        WlrLayershell.keyboardFocus = WlrKeyboardFocus.None
                        hideAnimationTimer.restart()
                    }
                })
            }
        }
    }

    // Keyboard navigation
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            // Start hide animation
            historyPanel._showAnimation = false
            historyPanel._isHiding = true
            hideAnimationTimer.restart()
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            navigateDown()
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            navigateUp()
            event.accepted = true
        } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            toggleExpandSelected()
            event.accepted = true
        } else if (event.key === Qt.Key_D) {
            deleteSelected()
            event.accepted = true
        }
    }

    function navigateDown() {
        if (groupedNotifications.length === 0) return
        
        if (isGroupSelected) {
            // Check if group is expanded by finding the component
            let groupExpanded = false
            for (let i = 0; i < groupsColumn.children.length; i++) {
                const child = groupsColumn.children[i]
                if (child && child.objectName === "notificationGroup" + selectedGroupIndex) {
                    groupExpanded = child.expanded || false
                    break
                }
            }
            
            const group = groupedNotifications[selectedGroupIndex]
            if (group && group.notifications && group.notifications.length > 0 && groupExpanded) {
                // Move to first notification in group
                isGroupSelected = false
                selectedNotificationIndex = 0
            } else {
                // Move to next group
                if (selectedGroupIndex < groupedNotifications.length - 1) {
                    selectedGroupIndex++
                }
            }
        } else {
            const group = groupedNotifications[selectedGroupIndex]
            if (group && group.notifications) {
                if (selectedNotificationIndex < group.notifications.length - 1) {
                    selectedNotificationIndex++
                } else {
                    // Move to next group
                    if (selectedGroupIndex < groupedNotifications.length - 1) {
                        selectedGroupIndex++
                        selectedNotificationIndex = -1
                        isGroupSelected = true
                    }
                }
            }
        }
        scrollToSelected()
    }

    function navigateUp() {
        if (groupedNotifications.length === 0) return
        
        if (isGroupSelected) {
            // Move to previous group
            if (selectedGroupIndex > 0) {
                selectedGroupIndex--
                // Check if previous group is expanded
                let prevGroupExpanded = false
                for (let i = 0; i < groupsColumn.children.length; i++) {
                    const child = groupsColumn.children[i]
                    if (child && child.objectName === "notificationGroup" + selectedGroupIndex) {
                        prevGroupExpanded = child.expanded || false
                        break
                    }
                }
                const prevGroup = groupedNotifications[selectedGroupIndex]
                if (prevGroup && prevGroup.notifications && prevGroup.notifications.length > 0 && prevGroupExpanded) {
                    // Move to last notification in previous group
                    isGroupSelected = false
                    selectedNotificationIndex = prevGroup.notifications.length - 1
                }
            }
        } else {
            if (selectedNotificationIndex > 0) {
                selectedNotificationIndex--
            } else {
                // Move to group header
                isGroupSelected = true
                selectedNotificationIndex = -1
            }
        }
        scrollToSelected()
    }
    
    function scrollToSelected() {
        Qt.callLater(() => {
            if (!scrollView || !scrollView.contentItem) return
            
            // Find the selected group component
            let selectedGroup = null
            for (let i = 0; i < groupsColumn.children.length; i++) {
                const child = groupsColumn.children[i]
                if (child && child.objectName === "notificationGroup" + selectedGroupIndex) {
                    selectedGroup = child
                    break
                }
            }
            
            if (!selectedGroup) return
            
            // Get the Flickable (ScrollView's contentItem)
            const flickable = scrollView.contentItem
            if (!flickable || typeof flickable.contentY === 'undefined') return
            
            // Calculate Y position of selected item relative to groupsColumn
            let targetY = 0
            
            // Accumulate Y positions of groups before selected one
            for (let i = 0; i < selectedGroupIndex; i++) {
                for (let j = 0; j < groupsColumn.children.length; j++) {
                    const child = groupsColumn.children[j]
                    if (child && child.objectName === "notificationGroup" + i) {
                        targetY += child.height
                        break
                    }
                }
            }
            
            if (isGroupSelected) {
                // Scroll to group header - targetY already points to start of group
                // Add a small offset for the header
            } else {
                // Scroll to notification within group
                // Find the notificationsList Column
                let notificationsColumn = null
                for (let i = 0; i < selectedGroup.children.length; i++) {
                    const child = selectedGroup.children[i]
                    if (child && child.objectName === "contentColumn") {
                        // Find notificationsList Column (second child)
                        if (child.children && child.children.length > 1) {
                            notificationsColumn = child.children[1]
                        }
                        break
                    }
                }
                
                if (notificationsColumn) {
                    // Add header height
                    targetY += 60 // Approximate header height
                    
                    // Find the selected notification item and add its offset
                    for (let j = 0; j < notificationsColumn.children.length; j++) {
                        const child = notificationsColumn.children[j]
                        if (child && child.objectName === "notificationItem" + selectedNotificationIndex) {
                            targetY += child.y
                            break
                        }
                    }
                    // Fallback: approximate based on index
                    if (targetY < 60) {
                        targetY += 60 + (selectedNotificationIndex * 80)
                    }
                }
            }
            
            // Scroll to show the selected item
            const viewportHeight = scrollView.height
            const currentY = flickable.contentY
            const itemHeight = isGroupSelected ? 60 : 80
            
            // If item is above viewport, scroll up
            if (targetY < currentY) {
                flickable.contentY = Math.max(0, targetY - 20) // 20px padding
            }
            // If item is below viewport, scroll down
            else if (targetY + itemHeight > currentY + viewportHeight) {
                flickable.contentY = Math.min(flickable.contentHeight - viewportHeight, targetY - viewportHeight + itemHeight + 20) // 20px padding
            }
        })
    }

    function toggleExpandSelected() {
        if (selectedGroupIndex >= 0 && selectedGroupIndex < groupedNotifications.length) {
            // Find the group component in the Repeater
            for (let i = 0; i < groupsColumn.children.length; i++) {
                const child = groupsColumn.children[i]
                if (child && child.objectName === "notificationGroup" + selectedGroupIndex) {
                    if (typeof child.toggleExpand === 'function') {
                        child.toggleExpand()
                    }
                    break
                }
            }
        }
    }

    function deleteSelected() {
        if (selectedGroupIndex < 0 || selectedGroupIndex >= groupedNotifications.length) return
        
        const group = groupedNotifications[selectedGroupIndex]
        if (!group) return
        
        // Check if a notification is selected (more explicit check)
        if (!isGroupSelected && selectedNotificationIndex >= 0 && group.notifications && selectedNotificationIndex < group.notifications.length) {
            // Delete single notification
            const notification = group.notifications[selectedNotificationIndex]
            NotificationStore.removeNotification(group.appName, notification.id)
            updateNotifications()
            // Adjust selection
            const updatedGroup = groupedNotifications[selectedGroupIndex]
            if (updatedGroup && updatedGroup.notifications) {
                if (selectedNotificationIndex >= updatedGroup.notifications.length) {
                    selectedNotificationIndex = Math.max(0, updatedGroup.notifications.length - 1)
                }
                if (updatedGroup.notifications.length === 0) {
                    isGroupSelected = true
                    selectedNotificationIndex = -1
                }
            }
        } else if (isGroupSelected) {
            // Delete entire group
            NotificationStore.clearApp(group.appName)
            updateNotifications()
            // Adjust selection
            if (selectedGroupIndex >= groupedNotifications.length) {
                selectedGroupIndex = Math.max(0, groupedNotifications.length - 1)
            }
        }
    }

    // Remove PanelWindow property animation - causes tearing
    // Animated height behavior removed - animations are on Item types inside

    // Timer to delay hiding to allow animation to complete
    Timer {
        id: hideAnimationTimer
        interval: Settings.animationDurationMedium
        onTriggered: {
            // Animation should be complete now - actually hide the panel
            if (_isHiding) {
                _completingHide = true  // Mark that we're completing the hide
                _isHiding = false
                visible = false
                Qt.callLater(() => {
                    _completingHide = false  // Reset after hide completes
                })
            }
        }
    }

    // IPC handler
    IpcHandler {
        function toggleHistory() {
            if (historyPanel.visible) {
                // Start hide animation
                historyPanel._showAnimation = false
                historyPanel._isHiding = true
                // Delay actually hiding until animation completes
                hideAnimationTimer.restart()
            } else {
                // Show immediately
                historyPanel.visible = true
            }
        }

        target: "notificationHistory"
    }
    
    function hidePanel() {
        // Actually hide the panel after animation completes
        visible = false
    }

    // Container with animations
    Item {
        id: container
        anchors.fill: parent
        clip: true  // Clip for smooth edges
        focus: true

        // Only enable layer rendering when visible to save memory
        layer.enabled: visible
        layer.smooth: true
        
        // Handle keyboard events here as well to ensure they're captured
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                historyPanel.visible = false
                event.accepted = true
            } else if (event.key === Qt.Key_Down) {
                historyPanel.navigateDown()
                event.accepted = true
            } else if (event.key === Qt.Key_Up) {
                historyPanel.navigateUp()
                event.accepted = true
            } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                historyPanel.toggleExpandSelected()
                event.accepted = true
            } else if (event.key === Qt.Key_D) {
                historyPanel.deleteSelected()
                event.accepted = true
            }
        }

        // Slide animation from right (Windows-style sidebar)
        transform: Translate {
            id: slideTransform
            x: historyPanel._showAnimation ? 0 : sidebarWidth  // Slide in from right

            Behavior on x {
                // Always enabled to allow hide animation
                NumberAnimation {
                    duration: Settings.animationDurationMedium
                    easing.type: Easing.OutCubic
                }
            }
        }

        // Fade animation - animate based on _showAnimation, not visible
        opacity: historyPanel._showAnimation ? 1 : 0

        Behavior on opacity {
            // Always enabled to allow hide animation
            NumberAnimation {
                duration: Settings.animationDurationShort
                easing.type: Easing.Linear
            }
        }

        // Main card
        Card {
            id: mainCard

            anchors.fill: parent
            showBorder: true
            contentPadding: Settings.cardPadding

            Item {
                id: contentWrapper
                anchors.fill: parent

                Column {
                    id: contentColumn

                    width: parent.width
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 14
                    
                    onImplicitHeightChanged: {
                        historyPanel.panelContentHeight = implicitHeight
                    }
                    
                    Component.onCompleted: {
                        historyPanel.panelContentHeight = implicitHeight
                    }

                    // Header
                    RowLayout {
                        id: headerRow
                        width: parent.width
                        spacing: 12

                        Text {
                            Layout.fillWidth: true
                            text: "Notification History"
                            color: Theme.textPrimary
                            font.pixelSize: Settings.fontSizeLarge
                            font.weight: Font.Bold
                        }

                        // Clear all button
                        IconButton {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            icon: "🗑"
                            iconSize: 14
                            buttonSize: 24

                            onClicked: {
                                NotificationStore.clearAll()
                                updateNotifications()
                            }
                        }
                    }
                }

                // Scrollable list of groups - fills remaining space
                ScrollView {
                    id: scrollView
                    width: parent.width
                    anchors.top: contentColumn.bottom
                    anchors.topMargin: 14
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    
                    clip: true

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width: 8
                    }

                    Column {
                        id: groupsColumn

                        width: parent.width
                        spacing: 12

                        Repeater {
                            model: historyPanel.groupedNotifications || []

                            delegate: NotificationHistoryGroup {
                                required property var modelData
                                required property int index
                                
                                objectName: "notificationGroup" + index
                                
                                width: groupsColumn.width
                                appName: modelData.appName || ""
                                notifications: modelData.notifications || []
                                isSelected: historyPanel.selectedGroupIndex === index && historyPanel.isGroupSelected
                                selectedNotificationIndex: historyPanel.selectedGroupIndex === index ? historyPanel.selectedNotificationIndex : -1

                                onNotificationDismissed: function(appName, notificationId) {
                                    NotificationStore.removeNotification(appName, notificationId)
                                    historyPanel.updateNotifications()
                                }
                                
                                onToggleExpandRequested: {
                                    if (historyPanel.selectedGroupIndex === index) {
                                        toggleExpand()
                                    }
                                }
                                
                                onExpandedStateChanged: {
                                    historyPanel.updateContentHeight()
                                }
                            }
                        }

                        // Empty state
                        Item {
                            width: groupsColumn.width
                            height: 100
                            visible: historyPanel.groupedNotifications.length === 0

                            Text {
                                anchors.centerIn: parent
                                text: "No notifications"
                                color: Theme.textSecondary
                                font.pixelSize: Settings.fontSizeMedium
                            }
                        }
                    }
                }
            }
        }
    }
}

