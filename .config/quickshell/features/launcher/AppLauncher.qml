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
    property var filteredApps: []
    property int selectedIndex: 0
    property bool _showAnimation: false
    property bool _itemsShouldAnimate: false
    property bool _isInitialShow: false
    readonly property int maxVisibleItems: 5
    readonly property int itemHeight: 30
    readonly property int searchBoxContentHeight: 30
    readonly property int searchBoxPadding: 10
    readonly property int listCardPadding: 5
    readonly property int verticalSpacing: 10
    readonly property int searchBoxTotalHeight: searchBoxContentHeight + (searchBoxPadding * 2)
    readonly property int listContentHeight: Math.min(filteredModel.count, maxVisibleItems) * itemHeight
    readonly property int listCardTotalHeight: listContentHeight + (listCardPadding * 2)
    readonly property int calculatedHeight: searchBoxTotalHeight + verticalSpacing + listCardTotalHeight

    function updateFilter() {
        filteredModel.clear();
        const searchText = searchInput.text.trim();
        
        // Don't animate items when typing, only on initial show
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
        
        // Store filtered apps separately (ListModel cannot store functions)
        filteredApps = appsToShow;
        
        // Add apps to model for display only (limit to maxVisibleItems)
        const maxItems = Math.min(appsToShow.length, maxVisibleItems);
        for (let i = 0; i < maxItems; i++) {
            const app = appsToShow[i];
            filteredModel.append({
                icon: app.icon || "",
                name: app.name || ""
            });
        }
        
        // Reset selection when filter changes
        selectedIndex = 0;
        if (listView.count > 0) {
            listView.currentIndex = 0;
        }
        
        // Only trigger item animations on initial show, not during typing
        if (_isInitialShow) {
            Qt.callLater(() => {
                _itemsShouldAnimate = true;
                _isInitialShow = false;
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
        if (filteredApps.length === 0) return;
        
        if (selectedIndex >= 0 && selectedIndex < filteredApps.length) {
            const app = filteredApps[selectedIndex];
            if (app && app.execute) {
                app.execute();
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
    }
    
    onVisibleChanged: {
        if (visible) {
            selectedIndex = 0;
            searchInput.text = "";
            // Mark this as initial show for animations
            _isInitialShow = true;
            updateFilter();
            WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive;
            // Reset animation states
            _showAnimation = false;
            _itemsShouldAnimate = false;
            // Force focus immediately when visible
            searchInput.forceActiveFocus();
            // Start animations smoothly
            Qt.callLater(() => {
                _showAnimation = true;
                // Delay item animations slightly after container animation starts
                itemAnimationTimer.restart();
            });
        } else {
            _showAnimation = false;
            _itemsShouldAnimate = false;
            _isInitialShow = false;
            WlrLayershell.keyboardFocus = WlrKeyboardFocus.None;
        }
    }
    
    // Handle keys at PanelWindow level as fallback
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
    
    // Animated height behavior - fast and responsive
    Behavior on implicitHeight {
        enabled: visible
        NumberAnimation {
            duration: Settings.animationDurationShort
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
            // Ensure focus is maintained
            if (appLauncher.visible) {
                searchInput.forceActiveFocus();
            }
        }
    }

    // Container with slide and fade animations
    Item {
        id: container
        anchors.fill: parent
        
        // Slide animation - only on initial show
        transform: Translate {
            id: slideTransform
            y: appLauncher._showAnimation ? 0 : -20
            
            Behavior on y {
                enabled: appLauncher.visible
                NumberAnimation {
                    duration: Settings.animationDurationShort
                    easing.type: Easing.OutCubic
                }
            }
        }
        
        // Fade animation - only on initial show/hide
        opacity: appLauncher.visible ? (appLauncher._showAnimation ? 1 : 0) : 0
        
        Behavior on opacity {
            enabled: appLauncher.visible
            NumberAnimation {
                duration: Settings.animationDurationShort
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
                selectByMouse: false
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
            
            // Animate height changes - fast and responsive
            Behavior on height {
                enabled: appLauncher.visible
                NumberAnimation {
                    duration: Settings.animationDurationShort
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
                        color: Theme.surfaceHighlight || Theme.accentContainer
                        opacity: 0.6
                        radius: 8
                        width: listView ? listView.width : 0
                        height: itemHeight
                        border.width: 2
                        border.color: Theme.accentPrimary || Theme.textPrimary
                    }

                    delegate: Item {
                        width: parent.width
                        height: itemHeight
                        property bool isSelected: listView.currentIndex === index
                        property bool shouldAnimate: appLauncher._itemsShouldAnimate

                        // Fade in animation - only on initial show
                        opacity: shouldAnimate ? 1 : (appLauncher.visible ? 1 : 0)
                        
                        Behavior on opacity {
                            enabled: shouldAnimate && appLauncher._isInitialShow
                            SequentialAnimation {
                                PauseAnimation {
                                    duration: index * 25 // Stagger each item by 25ms
                                }
                                NumberAnimation {
                                    duration: Settings.animationDurationShort
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        // Background highlight for selected item - no animation, instant feedback
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 2
                            color: isSelected ? (Theme.accentContainer || Theme.surfaceHighlight) : "transparent"
                            opacity: isSelected ? 0.8 : 0
                            radius: 8
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
                                color: isSelected ? (Theme.textOnPrimaryContainer || Theme.textPrimary) : Theme.textPrimary
                                font.pixelSize: 18
                                font.weight: isSelected ? Font.Medium : Font.Normal
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                selectedIndex = index;
                                listView.currentIndex = index;
                                executeSelected();
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
