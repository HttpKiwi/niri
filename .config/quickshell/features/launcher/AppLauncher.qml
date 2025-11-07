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

    property var allApps: []
    property var filteredApps: []
    property int selectedIndex: 0
    property bool _showAnimation: false
    property bool _itemsShouldAnimate: false
    property bool _isInitialShow: false
    readonly property int maxVisibleItems: 5
    readonly property int itemHeight: 40
    readonly property int searchBoxContentHeight: 30
    readonly property int searchBoxPadding: 10
    readonly property int listCardPadding: 5
    readonly property int verticalSpacing: 10
    readonly property int searchBoxTotalHeight: searchBoxContentHeight + (searchBoxPadding * 2)
    readonly property int listContentHeight: Math.min(filteredModel.count, maxVisibleItems) * itemHeight
    readonly property int listCardTotalHeight: listContentHeight + (listCardPadding * 2)
    readonly property int calculatedHeight: searchBoxTotalHeight + verticalSpacing + listCardTotalHeight
    readonly property int maxHeight: searchBoxTotalHeight + verticalSpacing + (maxVisibleItems * itemHeight) + (listCardPadding * 2)

    function loadAppsIfNeeded() {
        // Lazy-load desktop entries only when needed
        if (allApps.length === 0) {
            const rawApps = DesktopEntries.applications.values || [];
            // Deduplicate apps by name to avoid showing duplicates
            const seenNames = new Set();
            const uniqueApps = [];
            for (let i = 0; i < rawApps.length; i++) {
                const app = rawApps[i];
                const appName = app.name || "";
                if (appName && !seenNames.has(appName)) {
                    seenNames.add(appName);
                    uniqueApps.push(app);
                }
            }
            allApps = uniqueApps;
        }
    }

    function updateFilter() {
        // Load apps if not already loaded
        loadAppsIfNeeded();
        
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
            // Convert icon name to path using Quickshell.iconPath()
            const iconPath = app.icon ? Quickshell.iconPath(app.icon, "") : "";
            filteredModel.append({
                icon: iconPath,
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
    implicitHeight: maxHeight  // Fixed maximum height to avoid PanelWindow animation
    color: "transparent"
    exclusiveZone: -1
    
    // Mask for smooth animations (required for transparent+mask pattern)
    mask: Region {
        item: container
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
            // Load apps when launcher becomes visible
            loadAppsIfNeeded();
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
            // Clear apps from memory when hidden to save memory
            allApps = [];
            filteredApps = [];
            filteredModel.clear();
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
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        clip: true  // Clip to animate visible height
        
        // Animated height for smooth appearance
        property real animatedHeight: appLauncher.visible && appLauncher._showAnimation ? calculatedHeight : 0
        
        height: animatedHeight
        
        Behavior on height {
            enabled: appLauncher.visible
            NumberAnimation {
                duration: Settings.animationDurationShort
                easing.type: Easing.OutQuad
            }
        }
        
        // Only enable layer when visible to save memory
        layer.enabled: appLauncher.visible
        layer.smooth: true
        
        // Slide animation - only on initial show
        transform: Translate {
            id: slideTransform
            y: appLauncher._showAnimation ? 0 : -15
            
            Behavior on y {
                enabled: appLauncher.visible
                NumberAnimation {
                    duration: Settings.animationDurationShort
                    easing.type: Easing.OutQuad  // Simpler easing for better performance
                }
            }
        }
        
        // Fade animation - only on initial show/hide
        opacity: appLauncher.visible ? (appLauncher._showAnimation ? 1 : 0) : 0
        
        Behavior on opacity {
            enabled: appLauncher.visible
            NumberAnimation {
                duration: Settings.animationDurationShort
                easing.type: Easing.Linear  // Linear for smoother opacity changes
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
            
            // Only enable layer when visible to save memory
            layer.enabled: appLauncher.visible
            layer.smooth: true

            TextInput {
                id: searchInput

                focus: true
                anchors.fill: parent
                font.pixelSize: 18
                color: Theme.textPrimary
                selectByMouse: false
                renderType: Text.QtRendering  // Better antialiasing than NativeRendering
                antialiasing: true
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
            
            // Only enable layer when visible to save memory
            layer.enabled: appLauncher.visible
            layer.smooth: false
            
            // Animate height changes - fast and responsive
            Behavior on height {
                enabled: appLauncher.visible
                NumberAnimation {
                    duration: Settings.animationDurationShort
                    easing.type: Easing.OutQuad  // Simpler easing
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
                    
                    // Performance optimizations
                    cacheBuffer: itemHeight * 2  // Cache 2 items ahead
                    highlightMoveDuration: 100  // Fast highlight movement
                    highlightMoveVelocity: -1  // Disable velocity-based movement

                    highlight: Rectangle {
                        color: Theme.surfaceHighlight || Theme.accentContainer
                        opacity: 0.6
                        radius: 8
                        width: listView ? listView.width : 0
                        height: itemHeight
                        border.width: 2
                        border.color: Theme.accentPrimary || Theme.textPrimary
                        
                        // Only enable layer when launcher is visible
                        layer.enabled: appLauncher.visible
                        layer.smooth: true
                    }

                    delegate: Item {
                        width: parent.width
                        height: itemHeight
                        property bool isSelected: listView.currentIndex === index
                        property bool shouldAnimate: appLauncher._itemsShouldAnimate

                        // Cache delegates for better performance
                        layer.enabled: false  // Disable unless needed
                        
                        // Fade in animation - only on initial show, simplified
                        opacity: shouldAnimate ? 1 : (appLauncher.visible ? 1 : 0)
                        
                        Behavior on opacity {
                            enabled: shouldAnimate && appLauncher._isInitialShow
                            SequentialAnimation {
                                PauseAnimation {
                                    duration: index * 20 // Reduced stagger
                                }
                                NumberAnimation {
                                    duration: 120  // Shorter duration
                                    easing.type: Easing.OutQuad  // Simpler easing
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
                            antialiasing: true  // Smooth rounded corners
                        }

                        RowLayout {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 10
                            spacing: 10

                            Image {
                                source: model.icon || ""
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                Layout.alignment: Qt.AlignVCenter
                                fillMode: Image.PreserveAspectFit
                                smooth: true  // Enable for better icon quality
                                antialiasing: true  // Explicit antialiasing for icons
                                asynchronous: true  // Load async
                                cache: appLauncher.visible  // Only cache when launcher is visible
                                visible: model.icon !== ""
                            }

                            Text {
                                Layout.fillWidth: true
                                text: model.name || ""
                                color: isSelected ? (Theme.textOnPrimaryContainer || Theme.textPrimary) : Theme.textPrimary
                                font.pixelSize: 14
                                font.weight: isSelected ? Font.Medium : Font.Normal
                                elide: Text.ElideRight
                                renderType: Text.QtRendering  // Better antialiasing
                                antialiasing: true
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
