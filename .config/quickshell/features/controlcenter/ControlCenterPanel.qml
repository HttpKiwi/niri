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
    property int selectedNotificationIndex: -1  // list/visual index within expanded group (0 = top)
    property bool isGroupSelected: true

    property int expandedGroupIndex: -1
    // "notifications" | "controls"
    property string focusArea: "notifications"
    property int actionFocusIndex: 0
    property int audioFocusRow: 0 // 0 = sink, 1 = mic

    readonly property var tabOrder: ["audio", "record", "other"]

    readonly property string hintPrimary: "Super+N · Esc · Tab"
    readonly property string hintSecondary: {
        if (confirmDialog.isOpen)
            return "Enter confirm · Esc cancel";
        if (focusArea === "notifications")
            return "↑↓ · ←→ · Enter · D dismiss";
        if (controlsTab === "audio")
            return "1–3 tabs · ←→ volume · M mute";
        if (controlsTab === "record")
            return "1–3 tabs · Enter record · P pause";
        return "1–3 tabs · ←→↑↓ · Enter";
    }

    readonly property string controlsTab: {
        const t = Settings.controlCenterTab;
        return (t === "audio" || t === "record" || t === "other") ? t : "audio";
    }

    function setControlsTab(tabId) {
        if (tabId !== "audio" && tabId !== "record" && tabId !== "other")
            return;
        if (tabId === controlsTab)
            return;
        Settings.setPref("controlCenterTab", tabId);
    }

    implicitWidth: panelWidth
    width: panelWidth
    opacity: 1

    // Positioned by the host Loader in UnifiedBar (do not self-anchor to the window)

    function updateNotifications() {
        groupedNotifications = NotificationStore.getGroupedNotifications();
    }

    onOpened: {
        updateNotifications();
        selectedGroupIndex = groupedNotifications.length > 0 ? 0 : -1;
        selectedNotificationIndex = -1;
        isGroupSelected = true;
        expandedGroupIndex = -1;
        focusArea = "notifications";
        actionFocusIndex = 0;
        audioFocusRow = 0;
        Qt.callLater(() => keyboardScope.forceActiveFocus());
    }

    onClosed: {
        selectedNotificationIndex = -1;
        isGroupSelected = true;
        expandedGroupIndex = -1;
        focusArea = "notifications";
        if (confirmDialog.isOpen) {
            confirmDialog.isOpen = false;
            confirmDialog.cancelled();
        }
    }

    Connections {
        target: NotificationStore
        function onNotificationsChanged() {
            root.updateNotifications();
        }
    }

    Component.onCompleted: updateNotifications();

    function groupComponentAt(index) {
        return groupsRepeater.itemAt(index)
    }

    function navigateDown() {
        if (groupedNotifications.length === 0) return;

        if (isGroupSelected) {
            if (selectedGroupIndex < groupedNotifications.length - 1)
                selectedGroupIndex++;
        } else {
            const group = groupedNotifications[selectedGroupIndex];
            if (group?.notifications) {
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
            if (selectedGroupIndex > 0)
                selectedGroupIndex--;
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
            if (!scrollView) return;
            const flickable = scrollView.contentItem;
            if (!flickable) return;

            const viewportHeight = scrollView.height;
            const contentHeight = flickable.contentHeight;
            if (contentHeight <= viewportHeight) return;

            const targetGroup = root.groupComponentAt(selectedGroupIndex);
            if (!targetGroup) return;

            const groupY = targetGroup.y;
            const groupHeight = targetGroup.height;
            const currentY = flickable.contentY;
            const margin = 10;

            if (groupY < currentY + margin) {
                flickable.contentY = Math.max(0, groupY - margin);
            } else if (groupY + groupHeight > currentY + viewportHeight - margin) {
                flickable.contentY = Math.min(
                    contentHeight - viewportHeight,
                    groupY + groupHeight - viewportHeight + margin
                );
            }
        });
    }

    function expandSelectedGroup() {
        if (!isGroupSelected || selectedGroupIndex < 0)
            return;
        expandedGroupIndex = selectedGroupIndex;
    }

    function activateSelected() {
        if (isGroupSelected) {
            expandSelectedGroup();
            return;
        }
        if (selectedNotificationIndex < 0)
            return;
        if (selectedGroupIndex < 0 || selectedGroupIndex >= groupedNotifications.length)
            return;

        const groupComponent = groupComponentAt(selectedGroupIndex);
        if (groupComponent && typeof groupComponent.activateNotificationAt === "function")
            groupComponent.activateNotificationAt(selectedNotificationIndex);
    }

    function deleteSelected() {
        if (selectedGroupIndex < 0 || selectedGroupIndex >= groupedNotifications.length) return;

        const group = groupedNotifications[selectedGroupIndex];
        if (!group) return;

        const groupComponent = groupComponentAt(selectedGroupIndex);

        if (!isGroupSelected && selectedNotificationIndex >= 0 && group.notifications && selectedNotificationIndex < group.notifications.length) {
            if (groupComponent && typeof groupComponent.dismissNotificationAt === "function")
                groupComponent.dismissNotificationAt(selectedNotificationIndex);
            else {
                NotificationStore.dismissNotification(group.notifications[selectedNotificationIndex].id);
                updateNotifications();
                adjustSelectionAfterDelete();
            }
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

    function cycleFocusArea() {
        focusArea = focusArea === "notifications" ? "controls" : "notifications";
    }

    function shiftTab(delta) {
        const order = root.tabOrder;
        const cur = order.indexOf(controlsTab);
        const next = (cur + delta + order.length) % order.length;
        setControlsTab(order[next]);
    }

    function handleControlsKeys(event) {
        // Tab switch via 1/2/3
        if (event.key === Qt.Key_1) {
            setControlsTab("audio");
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_2) {
            setControlsTab("record");
            event.accepted = true;
            return;
        }
        if (event.key === Qt.Key_3) {
            setControlsTab("other");
            event.accepted = true;
            return;
        }

        if (controlsTab === "audio") {
            if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
                audioFocusRow = event.key === Qt.Key_Up ? 0 : 1;
                event.accepted = true;
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                const step = (event.modifiers & Qt.ShiftModifier) ? 0.05 : 0.02;
                const dir = event.key === Qt.Key_Right ? step : -step;
                if (audioFocusRow === 0)
                    Audio.setVolume(Audio.volume + dir);
                else
                    Audio.setMicVolume(Audio.micVolume + dir);
                event.accepted = true;
            } else if (event.key === Qt.Key_M) {
                if (audioFocusRow === 0)
                    Audio.toggleMute();
                else
                    Audio.toggleMicMute();
                event.accepted = true;
            }
            return;
        }

        if (controlsTab === "record") {
            if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                if (ScreenRecord.recording || ScreenRecord.pending)
                    ScreenRecord.stop();
                else
                    ScreenRecord.start();
                event.accepted = true;
            } else if (event.key === Qt.Key_P) {
                if (ScreenRecord.recording)
                    ScreenRecord.togglePause();
                event.accepted = true;
            } else if (event.key === Qt.Key_Left) {
                shiftTab(-1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                shiftTab(1);
                event.accepted = true;
            }
            return;
        }

        // other / system actions
        if (event.key === Qt.Key_Left) {
            actionFocusIndex = (actionFocusIndex + 5) % 6;
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            actionFocusIndex = (actionFocusIndex + 1) % 6;
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            actionFocusIndex = (actionFocusIndex + 3) % 6;
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            actionFocusIndex = (actionFocusIndex + 3) % 6;
            event.accepted = true;
        } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
            otherPage.activateFocused();
            event.accepted = true;
        }
    }

    FocusScope {
        id: keyboardScope
        anchors.fill: parent
        focus: root.shouldBeActive

        Keys.onPressed: (event) => {
            if (!root.shouldBeActive) return;

            if (confirmDialog.isOpen) {
                if (event.key === Qt.Key_Escape) {
                    confirmDialog.cancelled();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                    confirmDialog.confirmed();
                    event.accepted = true;
                }
                return;
            }

            if (event.key === Qt.Key_Escape) {
                if (panelState) panelState.controlCenter = false;
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Tab) {
                cycleFocusArea();
                event.accepted = true;
                return;
            }

            // Bracket keys always cycle tabs
            if (event.key === Qt.Key_BracketLeft) {
                focusArea = "controls";
                shiftTab(-1);
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_BracketRight) {
                focusArea = "controls";
                shiftTab(1);
                event.accepted = true;
                return;
            }

            if (focusArea === "controls") {
                handleControlsKeys(event);
                return;
            }

            // Notifications focus
            if (event.key === Qt.Key_Down) {
                navigateDown();
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                navigateUp();
                event.accepted = true;
            } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                activateSelected();
                event.accepted = true;
            } else if (event.key === Qt.Key_Left) {
                if (!isGroupSelected) {
                    isGroupSelected = true;
                    selectedNotificationIndex = -1;
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                if (isGroupSelected) {
                    const group = groupedNotifications[selectedGroupIndex];
                    if (group?.notifications?.length > 0) {
                        expandedGroupIndex = selectedGroupIndex;
                        isGroupSelected = false;
                        selectedNotificationIndex = 0;
                    }
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_D) {
                deleteSelected();
                event.accepted = true;
            } else if (event.key === Qt.Key_1 || event.key === Qt.Key_2 || event.key === Qt.Key_3) {
                focusArea = "controls";
                handleControlsKeys(event);
            }
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

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        spacing: 10

                        Text {
                            Layout.fillWidth: true
                            text: "Notifications"
                            color: Theme.textPrimary
                            font.family: Settings.fontFamilyDefault
                            font.pixelSize: Settings.fontSizeTitle
                            font.weight: Font.Bold
                        }

                        IconButton {
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            icon: "\ue872"
                            iconSize: 16
                            buttonSize: 24

                            onClicked: {
                                NotificationStore.clearAll();
                                root.updateNotifications();
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.hintPrimary
                        color: Theme.textSecondary
                        font.family: Settings.fontFamilyDefault
                        font.pixelSize: Settings.fontSizeCaption
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.hintSecondary
                        color: Theme.withAlpha(Theme.textSecondary, 0.85)
                        font.family: Settings.fontFamilyDefault
                        font.pixelSize: Settings.fontSizeCaption
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                    radius: Settings.cardRadius
                    border.width: root.focusArea === "notifications" && root.shouldBeActive ? 1 : 0
                    border.color: Theme.withAlpha(Theme.accent, 0.35)

                    ScrollView {
                        id: scrollView
                        anchors.fill: parent
                        anchors.margins: root.focusArea === "notifications" ? 1 : 0
                        clip: true
                        focus: false

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
                                id: groupsRepeater
                                model: root.groupedNotifications || []

                                delegate: NotificationHistoryGroup {
                                    required property var modelData
                                    required property int index

                                    objectName: "notificationGroup" + index
                                    width: groupsColumn.width
                                    appName: modelData.appName || ""
                                    notifications: modelData.notifications || []
                                    hasCritical: modelData.hasCritical || false
                                    expanded: root.expandedGroupIndex === index
                                    groupKeyboardFocused: root.shouldBeActive
                                        && root.focusArea === "notifications"
                                        && root.isGroupSelected
                                        && root.selectedGroupIndex === index
                                    focusedNotificationIndex: root.shouldBeActive
                                        && root.focusArea === "notifications"
                                        && !root.isGroupSelected
                                        && root.selectedGroupIndex === index
                                        ? root.selectedNotificationIndex
                                        : -1

                                    onToggleExpandRequested: {
                                        root.expandedGroupIndex = (root.expandedGroupIndex === index) ? -1 : index;
                                    }

                                    onNotificationDismissed: function(appName, notificationId) {
                                        NotificationService.dismissOnly(notificationId);
                                        root.updateNotifications();
                                        root.adjustSelectionAfterDelete();
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
                                    font.family: Settings.fontFamilyDefault
                                    font.pixelSize: Settings.fontSizeMedium
                                }
                            }
                        }
                    }
                }
            }
        }

        Column {
            id: controlsColumn
            Layout.fillWidth: true
            Layout.maximumHeight: contentColumn.height * 0.45 - 10
            spacing: 8
            clip: true

            // Scrim so tab labels stay readable over the chrome blob
            Rectangle {
                id: tabBarScrim
                width: parent.width
                height: 36
                radius: 18
                color: Theme.withAlpha(Theme.surfaceBase, 0.78)
                border.width: 1
                border.color: root.focusArea === "controls" && root.shouldBeActive
                    ? Theme.withAlpha(Theme.accent, 0.55)
                    : Theme.withAlpha(Theme.textPrimary, 0.08)

                Row {
                    id: tabRow
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4

                    Repeater {
                        model: [
                            { id: "audio", label: "Audio", hint: "1" },
                            { id: "record", label: "Record", hint: "2" },
                            { id: "other", label: "Other", hint: "3" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool selected: root.controlsTab === modelData.id

                            width: (tabRow.width - tabRow.spacing * 2) / 3
                            height: parent.height
                            radius: height / 2
                            color: selected
                                ? Theme.withAlpha(Theme.accent, 0.42)
                                : (tabMa.containsMouse ? Theme.withAlpha(Theme.textPrimary, 0.1) : "transparent")
                            border.width: selected ? 1 : 0
                            border.color: Theme.withAlpha(Theme.accent, 0.55)

                            Behavior on color {
                                ColorAnimation { duration: Settings.animationDurationShort }
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.label
                                    color: selected ? Theme.textOnPrimary : Theme.textPrimary
                                    font.family: Settings.fontFamilyDefault
                                    font.pixelSize: Settings.fontSizeSmall
                                    font.weight: selected ? Font.DemiBold : Font.Medium
                                    style: Text.Outline
                                    styleColor: Theme.withAlpha(Theme.surfaceBase, selected ? 0.35 : 0.65)

                                    Behavior on color {
                                        ColorAnimation { duration: Settings.animationDurationShort }
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.hint
                                    visible: root.focusArea === "controls"
                                    color: selected
                                        ? Theme.withAlpha(Theme.textOnPrimary, 0.7)
                                        : Theme.textSecondary
                                    font.family: Settings.fontFamilyDefault
                                    font.pixelSize: 9
                                    font.weight: Font.Medium
                                }
                            }

                            MouseArea {
                                id: tabMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.focusArea = "controls";
                                    root.setControlsTab(modelData.id);
                                }
                            }
                        }
                    }
                }
            }

            // Fixed-height page host — max of all tabs so the selector never jumps
            Item {
                id: tabPages
                width: parent.width
                readonly property int pagesHeight: Math.max(
                    audioPage.implicitHeight,
                    recordPage.implicitHeight,
                    otherPage.implicitHeight
                )
                height: pagesHeight
                clip: true

                readonly property int slidePx: 28

                function pageX(tabId) {
                    const order = ["audio", "record", "other"];
                    const cur = order.indexOf(root.controlsTab);
                    const idx = order.indexOf(tabId);
                    if (idx === cur)
                        return 0;
                    return idx < cur ? -slidePx : slidePx;
                }

                Column {
                    id: audioPage
                    width: parent.width
                    spacing: 8
                    opacity: root.controlsTab === "audio" ? 1 : 0
                    x: tabPages.pageX("audio")
                    enabled: root.controlsTab === "audio"
                    z: root.controlsTab === "audio" ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Settings.animationDurationMedium
                            easing.type: Settings.easingStandard
                        }
                    }
                    Behavior on x {
                        NumberAnimation {
                            duration: Settings.animationDurationMedium
                            easing.type: Settings.easingStandard
                        }
                    }

                    AudioSliders {
                        width: parent.width
                        keyboardActive: root.focusArea === "controls" && root.controlsTab === "audio"
                        focusedRow: root.audioFocusRow
                    }
                    MediaCard { width: parent.width }
                }

                ScreenRecordCard {
                    id: recordPage
                    width: parent.width
                    opacity: root.controlsTab === "record" ? 1 : 0
                    x: tabPages.pageX("record")
                    enabled: root.controlsTab === "record"
                    z: root.controlsTab === "record" ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Settings.animationDurationMedium
                            easing.type: Settings.easingStandard
                        }
                    }
                    Behavior on x {
                        NumberAnimation {
                            duration: Settings.animationDurationMedium
                            easing.type: Settings.easingStandard
                        }
                    }
                }

                SystemActions {
                    id: otherPage
                    width: parent.width
                    opacity: root.controlsTab === "other" ? 1 : 0
                    x: tabPages.pageX("other")
                    enabled: root.controlsTab === "other"
                    z: root.controlsTab === "other" ? 1 : 0
                    confirmDialog: confirmDialog
                    keyboardActive: root.focusArea === "controls" && root.controlsTab === "other"
                    focusedIndex: root.focusArea === "controls" && root.controlsTab === "other"
                        ? root.actionFocusIndex
                        : -1

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Settings.animationDurationMedium
                            easing.type: Settings.easingStandard
                        }
                    }
                    Behavior on x {
                        NumberAnimation {
                            duration: Settings.animationDurationMedium
                            easing.type: Settings.easingStandard
                        }
                    }
                }
            }
        }
    }

    ConfirmDialog {
        id: confirmDialog
        visible: false
    }
    }
}
