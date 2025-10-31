import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.core
import qs.components.base

PanelWindow {
    id: appLauncher

    property var allApps: DesktopEntries.applications.values
    property var filteredApps: DesktopEntries.applications.values
    property int selectedIndex: 0
    property bool _showAnimation: false
    property bool _itemsShouldAnimate: false
    readonly property int maxVisibleItems: 5
    readonly property int itemHeight: 70
    readonly property int searchBoxContentHeight: 70
    readonly property int searchBoxPadding: 20
    readonly property int listCardPadding: 5
    readonly property int verticalSpacing: 10
    readonly property int searchBoxTotalHeight: searchBoxContentHeight + (searchBoxPadding * 2)
    readonly property int listContentHeight: Math.min(filteredModel.count, maxVisibleItems) * itemHeight
    readonly property int listCardTotalHeight: listContentHeight + (listCardPadding * 2)
    readonly property int calculatedHeight: searchBoxTotalHeight + verticalSpacing + listCardTotalHeight

    function updateFilter() {
        filteredModel.clear();
        const searchText = searchInput.text.trim();
        
        // Reset item animations when filter changes
        _itemsShouldAnimate = false;
        
        let appsToShow;
        if (!searchText) {
            // Show all apps when search is empty
            appsToShow = allApps;
        } else {
            // Use FuzzyMatcher to filter and sort apps
            appsToShow = FuzzyMatcher.filterAndSort(allApps, searchText, function(app) {
                return app.name || "";
            });
        }
        
        // Add apps to model (limit to maxVisibleItems for display)
        const maxItems = Math.min(appsToShow.length, maxVisibleItems);
        for (let i = 0; i < maxItems; i++) {
            const app = appsToShow[i];
            filteredModel.append({
                icon: app.icon || "",
                name: app.name || "",
                execute: app.execute || function() {}
            });
        }
        
        // Reset selection when filter changes
        selectedIndex = 0;
        if (listView.count > 0) {
            listView.currentIndex = 0;
        }
        
        // Trigger item animations after model is updated
        if (visible) {
            Qt.callLater(() => {
                _itemsShouldAnimate = true;
            });
        }
    }

    function selectNext() {
        if (listView.count > 0) {
            selectedIndex = (selectedIndex + 1) % listView.count;
            listView.currentIndex = selectedIndex;
            listView.positionViewAtIndex(selectedIndex, ListView.Contain);
        }
    }

    function selectPrevious() {
        if (listView.count > 0) {
            selectedIndex = (selectedIndex - 1 + listView.count) % listView.count;
            listView.currentIndex = selectedIndex;
            listView.positionViewAtIndex(selectedIndex, ListView.Contain);
        }
    }

    function executeSelected() {
        if (filteredModel.count === 0) return;
        
        if (selectedIndex >= 0 && selectedIndex < filteredModel.count) {
            const item = filteredModel.get(selectedIndex);
            if (item && item.execute) {
                item.execute();
                appLauncher.visible = false;
            }
        }
    }

    visible: false
    implicitWidth: 400
    implicitHeight: calculatedHeight
    color: "transparent"
    exclusiveZone: -1
    
    // Position at center-top
    anchors {
        top: true
    }
    
    margins {
        top: 100
        left: (appLauncher.screen?.width || 1920) / 2 - implicitWidth / 2
        right: (appLauncher.screen?.width || 1920) / 2 - implicitWidth / 2
    }
    
    Component.onCompleted: {
        WlrLayershell.layer = WlrLayer.Overlay;
        WlrLayershell.namespace = "quickshell-app-launcher";
        console.log("App Launcher initialized");
    }
    
    onVisibleChanged: {
        if (visible) {
            selectedIndex = 0;
            searchInput.text = "";
            updateFilter();
            WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive;
            // Reset animation states
            _showAnimation = false;
            _itemsShouldAnimate = false;
            // Start animations smoothly
            Qt.callLater(() => {
                _showAnimation = true;
                // Delay item animations slightly after container animation starts
                itemAnimationTimer.restart();
            });
        } else {
            _showAnimation = false;
            _itemsShouldAnimate = false;
            WlrLayershell.keyboardFocus = WlrKeyboardFocus.None;
        }
    }
    
    // Animated height behavior - smoother with better easing
    Behavior on implicitHeight {
        enabled: visible
        NumberAnimation {
            duration: Settings.animationDurationMedium
            easing.type: Easing.OutCubic
        }
    }

    IpcHandler {
        function toggleLauncher() {
            appLauncher.visible = !appLauncher.visible;
        }

        target: "appLauncher"
    }

    ListModel {
        id: filteredModel
    }

    // Timer for delayed item animations
    Timer {
        id: itemAnimationTimer
        interval: 100
        onTriggered: {
            _itemsShouldAnimate = true;
            searchInput.forceActiveFocus();
        }
    }

    // Container with slide and fade animations
    Item {
        id: container
        anchors.fill: parent
        
        // Slide animation - smoother with better easing
        transform: Translate {
            id: slideTransform
            y: appLauncher._showAnimation ? 0 : -30
            
            Behavior on y {
                enabled: appLauncher.visible
                NumberAnimation {
                    duration: Settings.animationDurationMedium
                    easing.type: Easing.OutCubic
                }
            }
        }
        
        // Fade animation - fade in when visible
        opacity: appLauncher.visible ? (appLauncher._showAnimation ? 1 : 0) : 0
        
        Behavior on opacity {
            enabled: appLauncher.visible
            NumberAnimation {
                duration: Settings.animationDurationMedium
                easing.type: Easing.OutCubic
            }
        }
        
        // Search box card - fixed at top
        Card {
            id: searchCard
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: searchBoxTotalHeight
            showBorder: true
            contentPadding: searchBoxPadding

            TextInput {
                id: searchInput

                focus: true
                anchors.fill: parent
                font.pixelSize: 24
                color: Theme.textPrimary
                onTextChanged: updateFilter()
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        appLauncher.visible = false;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                        executeSelected();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down) {
                        selectNext();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        selectPrevious();
                        event.accepted = true;
                    }
                }
            }
        }

        // Results list card - positioned below search box, animates height
        Card {
            id: listCard
            anchors {
                top: searchCard.bottom
                topMargin: verticalSpacing
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: listCardTotalHeight
            showBorder: true
            contentPadding: listCardPadding
            
            // Animate height changes smoothly
            Behavior on height {
                enabled: appLauncher.visible
                NumberAnimation {
                    duration: Settings.animationDurationMedium
                    easing.type: Easing.OutCubic
                }
            }

                ListView {
                    id: listView

                    focus: false
                    anchors.fill: parent
                    model: filteredModel
                    currentIndex: selectedIndex
                    highlightFollowsCurrentItem: true
                    interactive: false

                    highlight: Rectangle {
                        color: Theme.surfaceHighlight || Theme.surfaceBase
                        opacity: 0.3
                        radius: 8
                        width: listView ? listView.width : 0
                        height: itemHeight
                    }

                    delegate: Item {
                        width: parent.width
                        height: itemHeight
                        property bool isSelected: listView.currentIndex === index
                        property bool shouldAnimate: appLauncher._itemsShouldAnimate

                        // Slide in from left animation
                        transform: Translate {
                            id: itemSlide
                            x: shouldAnimate ? 0 : -50
                            
                            Behavior on x {
                                enabled: shouldAnimate || appLauncher.visible
                                SequentialAnimation {
                                    PauseAnimation {
                                        duration: index * 30 // Stagger each item by 30ms
                                    }
                                    NumberAnimation {
                                        duration: Settings.animationDurationMedium
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }
                        
                        // Fade in animation
                        opacity: shouldAnimate ? 1 : 0
                        
                        Behavior on opacity {
                            enabled: shouldAnimate || appLauncher.visible
                            SequentialAnimation {
                                PauseAnimation {
                                    duration: index * 30 // Stagger each item by 30ms
                                }
                                NumberAnimation {
                                    duration: Settings.animationDurationMedium
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            color: isSelected ? (Theme.surfaceHighlight || Theme.surfaceBase) : "transparent"
                            opacity: isSelected ? 0.5 : 0
                            radius: 8
                            Behavior on opacity {
                                NumberAnimation { 
                                    duration: Settings.animationDurationShort
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        RowLayout {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 10
                            spacing: 10

                            Image {
                                source: model.icon ? model.icon : "image-missing"
                                width: 48
                                height: 48
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }

                            Text {
                                Layout.fillWidth: true
                                text: model.name || ""
                                color: Theme.textPrimary
                                font.pixelSize: 18
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (model.execute) {
                                    model.execute();
                                    appLauncher.visible = false;
                                }
                            }
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: {
                                selectedIndex = index;
                                listView.currentIndex = index;
                            }
                        }
                    }
                }
            }
        }

}
