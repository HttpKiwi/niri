import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.core
import qs.components.base
import qs.features.launcher

PanelWindow {
    id: launcher

    property var sources: [appLauncherSource, clipboardLauncherSource]
    property int currentSourceIndex: 0
    property var source: sources[currentSourceIndex]
    property var filteredItems: []
    property int selectedIndex: 0
    property bool _showAnimation: false
    property bool _itemsShouldAnimate: false
    property bool _isInitialShow: false

    readonly property int maxVisibleItems: 10
    readonly property int itemHeight: 40
    readonly property int searchBoxContentHeight: 30
    readonly property int searchBoxPadding: 10
    readonly property int listCardPadding: 5
    readonly property int verticalSpacing: 10
    readonly property int tabBarHeight: 20
    readonly property int tabBarSpacing: 6
    readonly property int searchBoxTotalHeight: tabBarHeight + tabBarSpacing + searchBoxContentHeight + (searchBoxPadding * 2)
    readonly property int listContentHeight: Math.min(filteredModel.count, maxVisibleItems) * itemHeight
    readonly property int listCardTotalHeight: listContentHeight + (listCardPadding * 2)
    readonly property int calculatedHeight: searchBoxTotalHeight + verticalSpacing + listCardTotalHeight
    readonly property int maxHeight: searchBoxTotalHeight + verticalSpacing + (maxVisibleItems * itemHeight) + (listCardPadding * 2)

    function updateFilter() {
        filteredModel.clear();
        
        var searchText = searchInput.text.trim();

        _itemsShouldAnimate = false;

        // Ensure source is loaded
        source.loadItems();

        var itemsToShow;
        if (!searchText) {
            itemsToShow = source.items;
        } else {
            itemsToShow = source.filterItems(searchText);
        }

        filteredItems = itemsToShow;

        for (var j = 0; j < itemsToShow.length; j++) {
            var item = itemsToShow[j];
            var display = source.getItemDisplay(item);
            filteredModel.append({
                icon: display.icon || "",
                title: display.title || "",
                subtitle: display.subtitle || ""
            });
        }

        selectedIndex = 0;
        if (listView.count > 0) {
            listView.currentIndex = 0;
        }

        if (_isInitialShow) {
            Qt.callLater(function() {
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
        if (filteredItems.length === 0) return;

        if (selectedIndex >= 0 && selectedIndex < filteredItems.length) {
            var item = filteredItems[selectedIndex];
            if (item) {
                source.executeItem(item);
                _showAnimation = false;
                _isHiding = true;
                hideAnimationTimer.restart();
            }
        }
    }

    function switchToSource(index) {
        if (index >= 0 && index < sources.length) {
            currentSourceIndex = index;
            selectedIndex = 0;
            searchInput.text = "";
            Qt.callLater(function() {
                source.loadItems();
                updateFilter();
            });
        }
    }

    function switchToSourceByName(name) {
        for (var i = 0; i < sources.length; i++) {
            if (sources[i].sourceName === name) {
                switchToSource(i);
                return;
            }
        }
    }

    function toggle() {
        if (launcher.visible) {
            _showAnimation = false;
            _isHiding = true;
            hideAnimationTimer.restart();
        } else {
            launcher.visible = true;
            currentSourceIndex = 0;
            selectedIndex = 0;
            searchInput.text = "";
            _isInitialShow = true;
            source.loadItems();
            updateFilter();
            WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive;
            _showAnimation = false;
            _itemsShouldAnimate = false;
            container.forceActiveFocus();
            searchInput.forceActiveFocus();
            Qt.callLater(function() {
                container.forceActiveFocus();
                searchInput.forceActiveFocus();
            });
            Qt.callLater(function() {
                _showAnimation = true;
                itemAnimationTimer.restart();
            });
        }
    }

    visible: false
    
    property bool _isHiding: false
    
    implicitWidth: 400
    implicitHeight: maxHeight
    color: "transparent"
    exclusiveZone: -1
    
    mask: Region {
        item: container
    }
    
    property int _centerX: {
        var screen = launcher.screen;
        if (!screen) return 960;
        var w = screen.width;
        if (!w) return 960;
        return (w - implicitWidth) / 2;
    }
    
    anchors {
        top: true
    }
    
    margins {
        top: 100
        left: _centerX
        right: _centerX
    }
    
    Component.onCompleted: {
        WlrLayershell.layer = WlrLayer.Overlay;
        WlrLayershell.namespace = "quickshell-launcher";
    }
    
    onVisibleChanged: {
        if (visible) {
            WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive;
            container.forceActiveFocus();
            searchInput.forceActiveFocus();
            Qt.callLater(() => {
                container.forceActiveFocus();
                searchInput.forceActiveFocus();
            });
        } else {
            WlrLayershell.keyboardFocus = WlrKeyboardFocus.None;
        }
    }
    
    IpcHandler {
        function toggleLauncher() {
            currentSourceIndex = 0;
            selectedIndex = 0;
            launcher.toggle();
        }

        function toggleClipboard() {
            currentSourceIndex = 1;
            selectedIndex = 0;
            if (launcher.visible) {
                source.loadItems();
                updateFilter();
            } else {
                launcher.visible = true;
                searchInput.text = "";
                _isInitialShow = true;
                source.loadItems();
                updateFilter();
                WlrLayershell.keyboardFocus = WlrKeyboardFocus.Exclusive;
                _showAnimation = false;
                _itemsShouldAnimate = false;
                container.forceActiveFocus();
                searchInput.forceActiveFocus();
                Qt.callLater(function() {
                    container.forceActiveFocus();
                    searchInput.forceActiveFocus();
                });
                Qt.callLater(function() {
                    _showAnimation = true;
                    itemAnimationTimer.restart();
                });
            }
        }

        target: "appLauncher"
    }

    AppLauncherSource {
        id: appLauncherSource
    }

    ClipboardLauncherSource {
        id: clipboardLauncherSource
        onItemsChanged: {
            if (currentSourceIndex === 1) {
                updateFilter();
            }
        }
    }

    ListModel {
        id: filteredModel
    }

    Timer {
        id: itemAnimationTimer
        interval: 100
        onTriggered: {
            _itemsShouldAnimate = true;
            if (launcher.visible) {
                searchInput.forceActiveFocus();
            }
        }
    }
    
    Timer {
        id: hideAnimationTimer
        interval: Settings.animationDurationShort
        onTriggered: {
            launcher.visible = false;
            launcher._isHiding = false;
        }
    }

    Item {
        id: container
        focus: true
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        clip: true
        
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
                launcher._showAnimation = false;
                launcher._isHiding = true;
                hideAnimationTimer.restart();
                WlrLayershell.keyboardFocus = WlrKeyboardFocus.None;
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
            } else if (event.key === Qt.Key_Tab) {
                if (event.modifiers & Qt.ShiftModifier) {
                    switchToSource((currentSourceIndex - 1 + sources.length) % sources.length);
                } else {
                    switchToSource((currentSourceIndex + 1) % sources.length);
                }
                event.accepted = true;
            }
        }
        
        property real animatedHeight: launcher.visible && launcher._showAnimation ? calculatedHeight : 0
        
        height: animatedHeight
        
        Behavior on height {
            enabled: launcher.visible
            NumberAnimation {
                duration: Settings.animationDurationShort
                easing.type: Easing.OutQuad
            }
        }
        
        layer.enabled: launcher.visible
        layer.smooth: true
        
        transform: Translate {
            id: slideTransform
            y: launcher._showAnimation ? 0 : -15
            
            Behavior on y {
                enabled: launcher.visible
                NumberAnimation {
                    duration: Settings.animationDurationShort
                    easing.type: Easing.OutQuad
                }
            }
        }
        
        opacity: launcher.visible ? (launcher._showAnimation ? 1 : 0) : 0
        
        Behavior on opacity {
            enabled: launcher.visible
            NumberAnimation {
                duration: Settings.animationDurationShort
                easing.type: Easing.Linear
            }
        }
        
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
            
            layer.enabled: launcher.visible
            layer.smooth: true

            Column {
                anchors.fill: parent
                spacing: 6

                Row {
                    id: tabBar
                    width: parent.width
                    height: 20
                    layoutDirection: Qt.LeftToRight
                    spacing: 8

                    Repeater {
                        model: sources
                        delegate: Item {
                            width: 100
                            height: parent.height

                            Rectangle {
                                id: tabBg
                                anchors.fill: parent
                                radius: 4
                                color: index === currentSourceIndex ? Theme.accentContainer : "transparent"
                                opacity: index === currentSourceIndex ? 0.8 : 0.3

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.displayName
                                    font.pixelSize: 11
                                    font.weight: index === currentSourceIndex ? Font.Bold : Font.Normal
                                    color: index === currentSourceIndex ? Theme.textOnPrimaryContainer : Theme.textSecondary
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    switchToSource(index);
                                }
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }
                }

                TextInput {
                    id: searchInput
                    width: parent.width
                    height: parent.height - tabBar.height - parent.spacing

                    focus: true
                    font.pixelSize: 18
                    color: Theme.textPrimary
                    selectByMouse: false
                    renderType: Text.QtRendering
                    antialiasing: true
                    onTextChanged: updateFilter()
                }
            }
        }

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
            
            layer.enabled: launcher.visible
            layer.smooth: false
            
            Behavior on height {
                enabled: launcher.visible
                NumberAnimation {
                    duration: Settings.animationDurationShort
                    easing.type: Easing.OutQuad
                }
            }

            ListView {
                id: listView

                focus: false
                anchors.fill: parent
                model: filteredModel
                currentIndex: selectedIndex
                highlightFollowsCurrentItem: true
                interactive: true
                
                cacheBuffer: itemHeight * 2
                highlightMoveDuration: 100
                highlightMoveVelocity: -1

                highlight: Rectangle {
                    color: Theme.surfaceHighlight || Theme.accentContainer
                    opacity: 0.6
                    radius: 12
                    width: listView ? listView.width : 0
                    height: itemHeight
                    antialiasing: true
                    border.width: 2
                    border.color: Theme.accentPrimary || Theme.textPrimary
                    
                    layer.enabled: launcher.visible
                    layer.smooth: true
                }

                delegate: Item {
                    width: parent ? parent.width : launcher.implicitWidth
                    height: itemHeight
                    property bool isSelected: listView.currentIndex === index
                    property bool shouldAnimate: launcher._itemsShouldAnimate

                    layer.enabled: false
                    
                    opacity: shouldAnimate ? 1 : (launcher.visible ? 1 : 0)
                    
                    Behavior on opacity {
                        enabled: shouldAnimate && launcher._isInitialShow
                        SequentialAnimation {
                            PauseAnimation {
                                duration: Math.max(0, index * 20)
                            }
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutQuad
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        color: isSelected ? (Theme.accentContainer || Theme.surfaceHighlight) : "transparent"
                        opacity: isSelected ? 0.8 : 0
                        radius: 8
                        antialiasing: true
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
                            smooth: true
                            antialiasing: true
                            asynchronous: true
                            cache: launcher.visible
                            visible: model.icon !== ""
                        }

                        Text {
                            Layout.fillWidth: true
                            text: model.title || ""
                            color: isSelected ? (Theme.textOnPrimaryContainer || Theme.textPrimary) : Theme.textPrimary
                            font.pixelSize: 14
                            font.weight: isSelected ? Font.Medium : Font.Normal
                            elide: Text.ElideRight
                            renderType: Text.QtRendering
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
