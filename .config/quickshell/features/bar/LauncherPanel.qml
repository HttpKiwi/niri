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

Item {
    id: root

    required property var panelState

    property var sources: [appLauncherSource, clipboardLauncherSource]
    property int currentSourceIndex: 0
    property var source: sources[currentSourceIndex]
    property var filteredItems: []
    property int selectedIndex: 0

    readonly property int maxVisibleItems: 10
    readonly property int itemHeight: 40
    readonly property int searchBoxContentHeight: 30
    readonly property int searchBoxPadding: 10
    readonly property int listCardPadding: 5
    readonly property int verticalSpacing: 10
    readonly property int tabBarHeight: 20
    readonly property int tabBarSpacing: 6
    readonly property int searchBoxTotalHeight: tabBarHeight + tabBarSpacing + searchBoxContentHeight + (searchBoxPadding * 2)
    property int listContentHeight: 0
    readonly property int listCardTotalHeight: listContentHeight + (listCardPadding * 2)
    readonly property int calculatedHeight: searchBoxTotalHeight + verticalSpacing + listCardTotalHeight

    readonly property bool shouldBeActive: panelState.launcher
    property real offsetScale: shouldBeActive ? 0 : 1

    visible: offsetScale < 1
    anchors.bottomMargin: (-implicitHeight - 5) * offsetScale
    implicitHeight: calculatedHeight
    implicitWidth: 500
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        NumberAnimation {
            duration: Settings.animationDurationShort
            easing.type: Easing.OutQuad
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: Settings.animationDurationShort
            easing.type: Easing.Linear
        }
    }

    Connections {
        target: panelState
        function onLauncherChanged() {
            if (panelState.launcher) {
                currentSourceIndex = panelState.clipboard ? 1 : 0;
                searchInput.text = "";
                updateFilter();
                Qt.callLater(function() { searchInput.forceActiveFocus(); });
            } else {
                searchInput.text = "";
                filteredModel.clear();
                listContentHeight = 0;
                selectedIndex = 0;
            }
        }
        function onClipboardChanged() {
            if (panelState.launcher) {
                currentSourceIndex = panelState.clipboard ? 1 : 0;
                if (panelState.clipboard) clipboardLauncherSource.refreshItems();
                updateFilter();
            }
        }
    }

    function switchToSource(index) {
        currentSourceIndex = index;
        selectedIndex = 0;
        if (index === 1) clipboardLauncherSource.refreshItems();
        updateFilter();
    }

    function updateFilter() {
        filteredModel.clear();
        var searchText = searchInput.text.trim();
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
        listContentHeight = Math.min(filteredModel.count, maxVisibleItems) * itemHeight;
        selectedIndex = 0;
        if (listView.count > 0) {
            listView.currentIndex = 0;
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
                panelState.launcher = false;
            }
        }
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

    Rectangle {
        anchors.fill: parent
        color: Theme.surfaceBase
        radius: Settings.screenCornerRadius
    }

    Column {
        anchors.fill: parent
        anchors.topMargin: 8
        spacing: 8

        Column {
            id: searchArea
            width: parent.width
            spacing: 6

            Row {
                id: tabBar
                width: parent.width
                height: 20
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

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.outline
                opacity: 0.2
            }

            TextInput {
                id: searchInput
                width: parent.width
                height: 30

                focus: true
                font.pixelSize: 18
                color: Theme.textPrimary
                selectByMouse: false
                renderType: Text.QtRendering
                antialiasing: true
                onTextChanged: updateFilter()

                Keys.onUpPressed: selectPrevious()
                Keys.onDownPressed: selectNext()
                Keys.onEscapePressed: panelState.launcher = false
                Keys.onReturnPressed: executeSelected()
                Keys.onEnterPressed: executeSelected()

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Tab) {
                        if (event.modifiers & Qt.ShiftModifier)
                            switchToSource((currentSourceIndex - 1 + sources.length) % sources.length);
                        else
                            switchToSource((currentSourceIndex + 1) % sources.length);
                        event.accepted = true;
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.outline
            opacity: 0.1
        }

            Item {
                id: listArea
                width: parent.width
                height: implicitHeight
                implicitHeight: listContentHeight
                clip: true

                Behavior on implicitHeight {
                    enabled: panelState.launcher
                    NumberAnimation {
                        duration: Settings.animationDurationShort
                        easing.type: Easing.OutQuad
                    }
                }

            ListView {
                id: listView

                anchors.fill: parent
                model: filteredModel
                currentIndex: selectedIndex
                highlightFollowsCurrentItem: true
                interactive: true

                cacheBuffer: itemHeight * 2
                highlightMoveDuration: 100
                highlightMoveVelocity: -1

                highlight: Rectangle {
                    color: Theme.accentContainer
                    opacity: 0.5
                    radius: 8
                    width: listView ? listView.width : 0
                    height: itemHeight
                }

                delegate: Item {
                    width: parent ? parent.width : 0
                    height: itemHeight
                    property bool isSelected: listView.currentIndex === index

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        color: isSelected ? Theme.accentContainer : "transparent"
                        opacity: isSelected ? 0.5 : 0
                        radius: 8
                        antialiasing: true
                    }

                    RowLayout {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
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
