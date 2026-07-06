pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.core
import qs.components.base
import qs.features.notifications
import qs.features.controlcenter

/**
 * ControlCenterPanel - Floating cards on the blob pocket (bar pattern).
 * No PanelWindow chrome — hosted inside UnifiedBar over PocketFrame.
 */
PocketSlidePanel {
    id: root

    panelFlag: "controlCenter"
    slideFrom: "right"
    slideDuration: Settings.animationDurationMedium

    property real screenWidth: 0
    property real screenHeight: 0
    property string screenName: ""

    readonly property int panelWidth: Settings.controlCenterWidth
    readonly property int pocketPadding: Settings.controlCenterPadding

    property var groupedNotifications: []
    property int selectedGroupIndex: -1
    property int selectedNotificationIndex: -1
    property bool isGroupSelected: true

    implicitWidth: panelWidth
    width: panelWidth
    opacity: 1
    focus: shouldBeActive

    anchors {
        top: parent.top
        bottom: parent.bottom
        right: parent.right
        topMargin: Settings.barHeight
        bottomMargin: Settings.screenBorderWidth
        rightMargin: Settings.screenBorderWidth
    }

    function updateNotifications() {
        groupedNotifications = NotificationStore.getGroupedNotifications();
    }

    onOpened: {
        updateNotifications();
        selectedGroupIndex = groupedNotifications.length > 0 ? 0 : -1;
        selectedNotificationIndex = -1;
        isGroupSelected = true;
        Qt.callLater(() => root.forceActiveFocus());
    }

    Connections {
        target: NotificationStore
        function onNotificationsChanged() {
            root.updateNotifications();
        }
    }

    Component.onCompleted: updateNotifications();

    Keys.onPressed: (event) => {
        if (!shouldBeActive) return;
        if (event.key === Qt.Key_Escape) {
            if (panelState) panelState.controlCenter = false;
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            navigateDown();
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            navigateUp();
            event.accepted = true;
        } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            toggleExpandSelected();
            event.accepted = true;
        } else if (event.key === Qt.Key_D) {
            deleteSelected();
            event.accepted = true;
        }
    }

    function navigateDown() {
        if (groupedNotifications.length === 0) return;

        if (isGroupSelected) {
            let groupExpanded = false;
            for (let i = 0; i < groupsColumn.children.length; i++) {
                const child = groupsColumn.children[i];
                if (child && child.objectName === "notificationGroup" + selectedGroupIndex) {
                    groupExpanded = child.expanded || false;
                    break;
                }
            }

            const group = groupedNotifications[selectedGroupIndex];
            if (group && group.notifications && group.notifications.length > 0 && groupExpanded) {
                isGroupSelected = false;
                selectedNotificationIndex = 0;
            } else if (selectedGroupIndex < groupedNotifications.length - 1) {
                selectedGroupIndex++;
            }
        } else {
            const group = groupedNotifications[selectedGroupIndex];
            if (group && group.notifications) {
                if (selectedNotificationIndex < group.notifications.length - 1) {
                    selectedNotificationIndex++;
                } else if (selectedGroupIndex < groupedNotifications.length - 1) {
                    selectedGroupIndex++;
                    selectedNotificationIndex = -1;
                    isGroupSelected = true;
                }
            }
        }
        scrollToSelected();
    }

    function navigateUp() {
        if (groupedNotifications.length === 0) return;

        if (isGroupSelected) {
            if (selectedGroupIndex > 0) {
                selectedGroupIndex--;
                let prevGroupExpanded = false;
                for (let i = 0; i < groupsColumn.children.length; i++) {
                    const child = groupsColumn.children[i];
                    if (child && child.objectName === "notificationGroup" + selectedGroupIndex) {
                        prevGroupExpanded = child.expanded || false;
                        break;
                    }
                }
                const prevGroup = groupedNotifications[selectedGroupIndex];
                if (prevGroup && prevGroup.notifications && prevGroup.notifications.length > 0 && prevGroupExpanded) {
                    isGroupSelected = false;
                    selectedNotificationIndex = prevGroup.notifications.length - 1;
                }
            }
        } else if (selectedNotificationIndex > 0) {
            selectedNotificationIndex--;
        } else {
            isGroupSelected = true;
            selectedNotificationIndex = -1;
        }
        scrollToSelected();
    }

    function scrollToSelected() {
        if (groupedNotifications.length === 0) return;

        Qt.callLater(() => {
            Qt.callLater(() => {
                if (!scrollView) return;
                const flickable = scrollView.contentItem;
                if (!flickable) return;

                const viewportHeight = scrollView.height;
                const currentY = flickable.contentY;
                const contentHeight = flickable.contentHeight;
                if (contentHeight <= viewportHeight) return;

                let targetGroup = null;
                for (let i = 0; i < groupsColumn.children.length; i++) {
                    const child = groupsColumn.children[i];
                    if (child && child.objectName === "notificationGroup" + selectedGroupIndex) {
                        targetGroup = child;
                        break;
                    }
                }
                if (!targetGroup) return;

                const groupY = targetGroup.y;
                const groupHeight = targetGroup.height;
                if (groupY < currentY) {
                    flickable.contentY = Math.max(0, groupY - 10);
                } else if (groupY + groupHeight > currentY + viewportHeight) {
                    flickable.contentY = Math.min(contentHeight - viewportHeight, groupY - viewportHeight + groupHeight + 10);
                }
            });
        });
    }

    function toggleExpandSelected() {
        if (selectedGroupIndex >= 0 && selectedGroupIndex < groupedNotifications.length) {
            for (let i = 0; i < groupsColumn.children.length; i++) {
                const child = groupsColumn.children[i];
                if (child && child.objectName === "notificationGroup" + selectedGroupIndex) {
                    if (typeof child.toggleExpand === "function")
                        child.toggleExpand();
                    break;
                }
            }
        }
    }

    function deleteSelected() {
        if (selectedGroupIndex < 0 || selectedGroupIndex >= groupedNotifications.length) return;

        const group = groupedNotifications[selectedGroupIndex];
        if (!group) return;

        let groupComponent = null;
        for (let i = 0; i < groupsColumn.children.length; i++) {
            const child = groupsColumn.children[i];
            if (child && child.objectName === "notificationGroup" + selectedGroupIndex) {
                groupComponent = child;
                break;
            }
        }

        if (!isGroupSelected && selectedNotificationIndex >= 0 && group.notifications && selectedNotificationIndex < group.notifications.length) {
            const notification = group.notifications[selectedNotificationIndex];
            NotificationStore.dismissNotification(notification.id);
            updateNotifications();
            adjustSelectionAfterDelete();
        } else if (isGroupSelected) {
            if (groupComponent && typeof groupComponent.startGroupDismiss === "function") {
                groupComponent.startGroupDismiss();
            } else {
                NotificationStore.clearApp(group.appName);
                updateNotifications();
                adjustSelectionAfterDelete();
            }
        }
    }

    function adjustSelectionAfterDelete() {
        const updatedGroup = groupedNotifications[selectedGroupIndex];
        if (updatedGroup && updatedGroup.notifications) {
            if (selectedNotificationIndex >= updatedGroup.notifications.length)
                selectedNotificationIndex = Math.max(0, updatedGroup.notifications.length - 1);
            if (updatedGroup.notifications.length === 0) {
                isGroupSelected = true;
                selectedNotificationIndex = -1;
            }
        }
        if (selectedGroupIndex >= groupedNotifications.length)
            selectedGroupIndex = Math.max(0, groupedNotifications.length - 1);
    }

    // Floating card stack — inset so blob shows a margin around cards
    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: root.pocketPadding
        spacing: 10

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: contentColumn.height * 0.6

            Column {
                anchors.fill: parent
                spacing: 8

                Row {
                    width: parent.width
                    height: 36
                    spacing: 10

                    Text {
                        width: parent.width - 34
                        text: "Notifications"
                        color: Theme.textPrimary
                        font.pixelSize: 14
                        font.weight: Font.Bold
                    }

                    IconButton {
                        width: 24
                        height: 24
                        icon: "\ue872"
                        iconSize: 16
                        buttonSize: 24

                        onClicked: {
                            NotificationStore.clearAll();
                            root.updateNotifications();
                        }
                    }
                }

                ScrollView {
                    id: scrollView
                    width: parent.width
                    height: parent.height - 44
                    clip: true

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        width: 6
                    }

                    Column {
                        id: groupsColumn
                        width: scrollView.width
                        height: childrenRect.height
                        spacing: 12

                        Repeater {
                            model: root.groupedNotifications || []

                            delegate: NotificationHistoryGroup {
                                required property var modelData
                                required property int index

                                objectName: "notificationGroup" + index
                                width: groupsColumn.width
                                appName: modelData.appName || ""
                                notifications: modelData.notifications || []
                                hasCritical: modelData.hasCritical || false

                                onNotificationDismissed: function(appName, notificationId) {
                                    NotificationService.dismissOnly(notificationId);
                                    root.updateNotifications();
                                }

                                onGroupDismissed: function(appName) {
                                    NotificationStore.clearApp(appName);
                                    root.updateNotifications();
                                    root.adjustSelectionAfterDelete();
                                }
                            }
                        }

                        Item {
                            width: groupsColumn.width
                            height: 80
                            visible: root.groupedNotifications.length === 0

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

        Column {
            id: controlsColumn
            Layout.fillWidth: true
            Layout.maximumHeight: contentColumn.height * 0.4 - 10
            spacing: 8

            AudioSliders {
                width: parent.width
            }

            MediaCard {
                width: parent.width
            }

            SystemActions {
                width: parent.width
                confirmDialog: confirmDialog
            }
        }
    }

    ConfirmDialog {
        id: confirmDialog
        visible: false
    }
}
