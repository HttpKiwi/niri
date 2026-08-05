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

PocketBottomPanel {
    id: root

    panelFlag: "launcher"
    bottomInset: 5

    property var sources: [appLauncherSource, clipboardLauncherSource, gifLauncherSource]
    property int currentSourceIndex: 0
    property var source: sources[currentSourceIndex]
    property var filteredItems: []
    property int selectedIndex: 0

    readonly property int maxVisibleItems: 10
    readonly property int itemHeight: source && source.sourceName === "clipboard" ? 48 : 40
    readonly property int searchInputHeight: 36
    readonly property int clipboardThumbSize: Settings.clipboardThumbSize
    readonly property int searchInputHorizontalPadding: 12
    readonly property int tabBarHeight: 28
    readonly property int topPadding: 12
    readonly property int bottomPadding: 12
    readonly property int separatorHeight: 1
    readonly property int searchAreaHeight: tabBarHeight + 8 + searchInputHeight
    property int listContentHeight: 0
    property bool _updatingFilter: false
    readonly property int calculatedHeight: searchAreaHeight + 8 + separatorHeight + listContentHeight + topPadding + bottomPadding
    readonly property int tabPillWidth: Math.max(88, Math.floor((500 - 12 * 2 - (sources.length - 1) * 6) / sources.length))
    readonly property bool isGifGrid: source.sourceName === "gifs"
    readonly property bool gifShowingStatus: isGifGrid && filteredModel.count > 0 && filteredModel.get(0).status
    readonly property int gifGridColumns: Settings.launcherGifGridColumns
    readonly property int gifGridSpacing: Settings.launcherGifGridSpacing
    readonly property int gifGridMaxHeight: Settings.launcherGifGridMaxHeight
    readonly property int gifCellWidth: isGifGrid
        ? Math.floor((implicitWidth - 24 - (gifGridColumns - 1) * gifGridSpacing) / gifGridColumns)
        : 0

    function computeGifCellHeight(mediaWidth, mediaHeight) {
        if (!mediaWidth || !mediaHeight)
            return gifCellWidth

        var height = Math.round(gifCellWidth * mediaHeight / mediaWidth)
        return Math.max(Settings.launcherGifCellMinHeight,
                        Math.min(Settings.launcherGifCellMaxHeight, height))
    }

    function computeGifGridContentHeight() {
        var columns = gifGridColumns
        var spacing = gifGridSpacing
        var rows = Math.ceil(filteredItems.length / columns)
        if (rows === 0)
            return 0

        var total = 0
        for (var row = 0; row < rows; row++) {
            var rowHeight = 0
            for (var col = 0; col < columns; col++) {
                var index = row * columns + col
                if (index >= filteredItems.length)
                    break
                var item = filteredItems[index]
                rowHeight = Math.max(rowHeight, computeGifCellHeight(item.width, item.height))
            }
            total += rowHeight
            if (row < rows - 1)
                total += spacing
        }
        return total
    }

    function gifCellPosition(index) {
        var columns = gifGridColumns
        var spacing = gifGridSpacing
        var row = Math.floor(index / columns)
        var col = index % columns
        var y = 0

        for (var r = 0; r < row; r++) {
            var rowHeight = 0
            for (var c = 0; c < columns; c++) {
                var rowIndex = r * columns + c
                if (rowIndex >= filteredItems.length)
                    break
                var rowItem = filteredItems[rowIndex]
                rowHeight = Math.max(rowHeight, computeGifCellHeight(rowItem.width, rowItem.height))
            }
            y += rowHeight + spacing
        }

        var height = computeGifCellHeight(filteredItems[index].width, filteredItems[index].height)
        var x = col * (gifCellWidth + spacing)
        return { x: x, y: y, width: gifCellWidth, height: height }
    }

    function positionGifCell(index) {
        if (!isGifGrid || index < 0 || index >= filteredItems.length)
            return

        var pos = gifCellPosition(index)
        var top = pos.y
        var bottom = top + pos.height
        if (top < gifFlickable.contentY)
            gifFlickable.contentY = top
        else if (bottom > gifFlickable.contentY + gifFlickable.height)
            gifFlickable.contentY = Math.max(0, bottom - gifFlickable.height)
    }

    implicitHeight: calculatedHeight
    implicitWidth: 500

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Settings.animationDurationShort
            easing.type: Easing.OutQuad
        }
    }

    onOpened: {
        applySourceSwitch(panelState.clipboard ? 1 : 0)
        searchInput.text = ""
        Qt.callLater(function() { searchInput.forceActiveFocus() })
    }

    onClosed: {
        searchInput.text = ""
        filteredModel.clear()
        listContentHeight = 0
        selectedIndex = 0
        currentSourceIndex = 0
        listArea._listOpacity = 1
        listArea._listOffsetX = 0
        gifFlickable.contentY = 0
    }

    Connections {
        target: panelState
        function onClipboardChanged() {
            if (!panelState.launcher)
                return
            // Only force Apps when leaving clipboard — don't yank away from GIFs
            if (panelState.clipboard)
                applySourceSwitch(1)
            else if (currentSourceIndex === 1)
                applySourceSwitch(0)
        }
    }

    function applySourceSwitch(index) {
        currentSourceIndex = index
        selectedIndex = 0
        if (panelState)
            panelState.clipboard = sources[index].sourceName === "clipboard"
        if (sources[index].sourceName === "clipboard")
            clipboardLauncherSource.softRefresh()
        updateFilter()
    }

    function switchToSource(index, animated) {
        if (index === currentSourceIndex || tabSwitchAnim.running)
            return

        if (animated === false) {
            applySourceSwitch(index)
            return
        }

        tabSwitchAnim.direction = index > currentSourceIndex ? 1 : -1
        tabSwitchAnim.pendingIndex = index
        tabSwitchAnim.start()
    }

    function updateFilter() {
        if (_updatingFilter)
            return
        _updatingFilter = true

        filteredModel.clear()
        const searchText = searchInput.text.trim()
        if (!source.isLoading)
            source.loadItems()

        if (source.isLoading) {
            filteredItems = []
            appendStatusRow(source.statusMessage || "Loading…")
            _updatingFilter = false
            return
        }

        let itemsToShow
        if (!searchText)
            itemsToShow = source.items
        else
            itemsToShow = source.filterItems(searchText)

        // Never dump unbounded history into the ListModel — freezes the UI thread
        const maxRows = Settings.launcherMaxModelItems
        if (itemsToShow && itemsToShow.length > maxRows)
            itemsToShow = itemsToShow.slice(0, maxRows)

        filteredItems = itemsToShow

        if (!itemsToShow.length) {
            if (source.statusMessage)
                appendStatusRow(source.statusMessage)
            else
                listContentHeight = 0
            selectedIndex = 0
            _updatingFilter = false
            return
        }

        for (let j = 0; j < itemsToShow.length; j++) {
            const item = itemsToShow[j]
            const display = source.getItemDisplay(item)
            filteredModel.append({
                icon: display.icon || "",
                gifUrl: item.previewUrl || item.url || display.icon || "",
                title: display.title || "",
                subtitle: display.subtitle || "",
                status: false,
                mediaWidth: item.width || 0,
                mediaHeight: item.height || 0
            })
        }

        if (isGifGrid) {
            listContentHeight = Math.min(computeGifGridContentHeight(), gifGridMaxHeight)
            gifFlickable.contentY = 0
        } else {
            listContentHeight = Math.min(filteredModel.count, maxVisibleItems) * itemHeight
        }
        selectedIndex = 0
        if (!isGifGrid && listView.count > 0)
            listView.currentIndex = 0

        _updatingFilter = false
    }

    function appendStatusRow(message) {
        filteredModel.append({
            icon: "",
            gifUrl: "",
            title: message,
            subtitle: "",
            status: true,
            mediaWidth: 0,
            mediaHeight: 0
        })
        listContentHeight = itemHeight
        selectedIndex = 0
    }

    function selectNext() {
        moveSelection(1)
    }

    function selectPrevious() {
        moveSelection(-1)
    }

    function moveSelection(delta) {
        if (isGifGrid && !gifShowingStatus) {
            moveGridHorizontal(delta)
            return
        }

        if (listView.count === 0)
            return

        let next = selectedIndex
        for (let i = 0; i < listView.count; i++) {
            next = (next + delta + listView.count) % listView.count
            if (!filteredModel.get(next).status)
                break
        }

        if (filteredModel.get(next).status)
            return

        selectedIndex = next
        listView.currentIndex = next
        listView.positionViewAtIndex(next, ListView.Contain)
    }

    function moveGridHorizontal(delta) {
        if (filteredItems.length === 0)
            return

        var columns = gifGridColumns
        var row = Math.floor(selectedIndex / columns)
        var col = selectedIndex % columns
        var nextCol = col + delta
        if (nextCol < 0 || nextCol >= columns)
            return

        var next = row * columns + nextCol
        if (next >= filteredItems.length)
            return

        selectedIndex = next
        positionGifCell(next)
    }

    function moveGridVertical(delta) {
        if (filteredItems.length === 0)
            return

        var columns = gifGridColumns
        var row = Math.floor(selectedIndex / columns)
        var col = selectedIndex % columns
        var nextRow = row + delta
        if (nextRow < 0 || nextRow >= Math.ceil(filteredItems.length / columns))
            return

        var next = nextRow * columns + col
        if (next >= filteredItems.length)
            next = filteredItems.length - 1

        selectedIndex = next
        positionGifCell(next)
    }

    function executeSelected() {
        if (filteredItems.length === 0)
            return
        if (selectedIndex >= 0 && selectedIndex < filteredItems.length) {
            if (filteredModel.get(selectedIndex).status)
                return
            const item = filteredItems[selectedIndex]
            if (item) {
                source.executeItem(item)
                panelState.launcher = false
            }
        }
    }

    AppLauncherSource {
        id: appLauncherSource
    }

    ClipboardLauncherSource {
        id: clipboardLauncherSource
        onItemsChanged: {
            if (source === clipboardLauncherSource)
                updateFilter()
        }
        onIsLoadingChanged: {
            if (source === clipboardLauncherSource)
                updateFilter()
        }
    }

    GifLauncherSource {
        id: gifLauncherSource
        onItemsUpdated: {
            if (source === gifLauncherSource)
                updateFilter()
        }
    }

    ListModel {
        id: filteredModel
    }

    SequentialAnimation {
        id: tabSwitchAnim
        property int direction: 1
        property int pendingIndex: 0

        ParallelAnimation {
            NumberAnimation {
                target: listArea
                property: "_listOpacity"
                to: 0
                duration: Settings.launcherTabTransitionMs / 2
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: listArea
                property: "_listOffsetX"
                to: tabSwitchAnim.direction * 18
                duration: Settings.launcherTabTransitionMs / 2
                easing.type: Easing.OutQuad
            }
        }

        ScriptAction {
            script: {
                root.applySourceSwitch(tabSwitchAnim.pendingIndex)
                listArea._listOffsetX = -tabSwitchAnim.direction * 18
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: listArea
                property: "_listOpacity"
                to: 1
                duration: Settings.launcherTabTransitionMs / 2
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: listArea
                property: "_listOffsetX"
                to: 0
                duration: Settings.launcherTabTransitionMs / 2
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Settings.chromeShaderEnabled ? "transparent" : Theme.withAlpha(Theme.surfaceBase, Settings.surfaceTransparency)
        radius: Settings.screenCornerRadius
    }

    Column {
        anchors.fill: parent
        anchors.topMargin: 12
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.bottomMargin: 12
        spacing: 8

        Column {
            id: searchArea
            width: parent.width
            spacing: 8

            Row {
                id: tabBar
                width: parent.width
                height: tabBarHeight
                spacing: 6

                Repeater {
                    model: sources
                    delegate: Pill {
                        width: tabPillWidth
                        height: parent.height
                        color: index === currentSourceIndex ? Theme.accentContainer : Theme.pillBackground
                        opacity: index === currentSourceIndex ? 1 : 0.55
                        scale: index === currentSourceIndex ? 1 : 0.98

                        Behavior on opacity {
                            NumberAnimation {
                                duration: Settings.launcherTabTransitionMs
                                easing.type: Easing.OutQuad
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: Settings.launcherTabTransitionMs
                                easing.type: Easing.OutCubic
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.displayName
                            font.pixelSize: 12
                            font.weight: index === currentSourceIndex ? Font.Bold : Font.Normal
                            color: index === currentSourceIndex ? Theme.textOnPrimaryContainer : Theme.textSecondary
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: switchToSource(index, true)
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: searchInputHeight
                radius: Theme.pillRadius
                color: Theme.pillBackground

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.leftMargin: searchInputHorizontalPadding
                    anchors.rightMargin: searchInputHorizontalPadding

                    focus: true
                    font.pixelSize: 16
                    color: Theme.textPrimary
                    selectByMouse: false
                    renderType: Text.QtRendering
                    antialiasing: true
                    verticalAlignment: Text.AlignVCenter
                    onTextChanged: updateFilter()

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: searchInputHorizontalPadding
                        anchors.rightMargin: searchInputHorizontalPadding
                        verticalAlignment: Text.AlignVCenter
                        text: source.searchPlaceholder || "Search"
                        font.pixelSize: 16
                        color: Theme.textSecondary
                        opacity: searchInput.text === "" ? 1 : 0
                        renderType: Text.QtRendering
                        antialiasing: true
                    }

                    Keys.onEscapePressed: panelState.launcher = false
                    Keys.onReturnPressed: executeSelected()
                    Keys.onEnterPressed: executeSelected()

                    Keys.onPressed: function(event) {
                        if (root.isGifGrid && !root.gifShowingStatus) {
                            if (event.key === Qt.Key_Left) {
                                root.moveGridHorizontal(-1)
                                event.accepted = true
                                return
                            }
                            if (event.key === Qt.Key_Right) {
                                root.moveGridHorizontal(1)
                                event.accepted = true
                                return
                            }
                            if (event.key === Qt.Key_Up) {
                                root.moveGridVertical(-1)
                                event.accepted = true
                                return
                            }
                            if (event.key === Qt.Key_Down) {
                                root.moveGridVertical(1)
                                event.accepted = true
                                return
                            }
                        } else if (event.key === Qt.Key_Up) {
                            selectPrevious()
                            event.accepted = true
                            return
                        } else if (event.key === Qt.Key_Down) {
                            selectNext()
                            event.accepted = true
                            return
                        }

                        if (event.key === Qt.Key_Tab) {
                            if (event.modifiers & Qt.ShiftModifier)
                                switchToSource((currentSourceIndex - 1 + sources.length) % sources.length, true)
                            else
                                switchToSource((currentSourceIndex + 1) % sources.length, true)
                            event.accepted = true
                        }
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
            height: listContentHeight
            clip: true

            property real _listOpacity: 1
            property real _listOffsetX: 0

            opacity: _listOpacity
            transform: Translate {
                x: listArea._listOffsetX
            }

            ListView {
                id: listView

                visible: !root.isGifGrid || root.gifShowingStatus
                anchors.fill: parent
                model: filteredModel
                currentIndex: selectedIndex
                highlightFollowsCurrentItem: true
                interactive: true

                cacheBuffer: itemHeight * 2
                highlightMoveDuration: 100
                highlightMoveVelocity: -1

                highlight: Rectangle {
                    visible: !root.isGifGrid
                        && listView.currentIndex >= 0
                        && listView.currentIndex < filteredModel.count
                        && !filteredModel.get(listView.currentIndex).status
                    color: Theme.glass(Math.min(Settings.glassOpacity + 0.08, 0.65), Settings.glassTintStrength)
                    border.color: Theme.glassBorder(Settings.glassBorderOpacity, Settings.glassTintStrength)
                    border.width: Settings.cardBorderWidth
                    radius: 8
                    antialiasing: true
                    width: listView ? listView.width : 0
                    height: itemHeight
                }

                delegate: Item {
                    width: parent ? parent.width : 0
                    height: root.isGifGrid ? itemHeight : itemHeight
                    visible: !root.isGifGrid || isStatus
                    property bool isSelected: listView.currentIndex === index
                    property bool isStatus: model.status

                    RowLayout {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Item {
                            id: thumbHost
                            visible: !isStatus && model.icon !== ""
                            Layout.preferredWidth: visible
                                ? (root.source && root.source.sourceName === "clipboard"
                                    ? root.clipboardThumbSize
                                    : 24)
                                : 0
                            Layout.preferredHeight: Layout.preferredWidth
                            Layout.alignment: Qt.AlignVCenter
                            clip: true

                            Rectangle {
                                anchors.fill: parent
                                radius: 6
                                color: Theme.glass(0.25, Settings.glassTintStrength)
                                visible: root.source && root.source.sourceName === "clipboard"
                            }

                            Image {
                                anchors.fill: parent
                                anchors.margins: root.source && root.source.sourceName === "clipboard" ? 0 : 0
                                source: model.icon || ""
                                fillMode: root.source && root.source.sourceName === "clipboard"
                                    ? Image.PreserveAspectCrop
                                    : Image.PreserveAspectFit
                                smooth: true
                                antialiasing: true
                                asynchronous: true
                                cache: true
                                visible: parent.visible

                                layer.enabled: root.source && root.source.sourceName === "clipboard"
                                layer.smooth: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: model.title || ""
                                color: isStatus
                                    ? Theme.textSecondary
                                    : (isSelected ? Theme.primary : Theme.textPrimary)
                                font.pixelSize: isStatus ? 13 : 14
                                font.weight: isSelected && !isStatus ? Font.Medium : Font.Normal
                                font.italic: isStatus
                                horizontalAlignment: isStatus ? Text.AlignHCenter : Text.AlignLeft
                                elide: Text.ElideRight
                                renderType: Text.QtRendering
                                antialiasing: true
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: !isStatus && model.subtitle !== ""
                                text: model.subtitle || ""
                                color: Theme.textSecondary
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !isStatus
                        onClicked: {
                            selectedIndex = index
                            listView.currentIndex = index
                            executeSelected()
                        }
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: {
                            if (!isStatus) {
                                selectedIndex = index
                                listView.currentIndex = index
                            }
                        }
                    }
                }
            }

            Flickable {
                id: gifFlickable

                visible: root.isGifGrid && !root.gifShowingStatus
                anchors.fill: parent
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                contentHeight: gifGrid.implicitHeight
                interactive: contentHeight > height

                GridLayout {
                    id: gifGrid
                    width: parent.width
                    columns: root.gifGridColumns
                    columnSpacing: root.gifGridSpacing
                    rowSpacing: root.gifGridSpacing

                    Repeater {
                        model: filteredModel

                        delegate: Item {
                            required property int index
                            required property string icon
                            required property string gifUrl
                            required property bool status
                            required property int mediaWidth
                            required property int mediaHeight

                            visible: !status
                            Layout.preferredWidth: root.gifCellWidth
                            Layout.preferredHeight: root.computeGifCellHeight(mediaWidth, mediaHeight)

                            property bool isSelected: root.selectedIndex === index
                            property bool shouldAnimate: gifMouseArea.containsMouse || isSelected

                            Rectangle {
                                anchors.fill: parent
                                radius: 10
                                color: Theme.pillBackground
                                opacity: gifMouseArea.containsMouse || isSelected ? 1 : 0.85

                                border.width: isSelected ? 2 : 0
                                border.color: Theme.primary
                            }

                            Image {
                                anchors.fill: parent
                                anchors.margins: 4
                                source: icon
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                smooth: true
                                antialiasing: true
                                visible: !shouldAnimate || gifAnim.status !== AnimatedImage.Ready
                            }

                            AnimatedImage {
                                id: gifAnim
                                anchors.fill: parent
                                anchors.margins: 4
                                source: gifUrl
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                smooth: true
                                playing: shouldAnimate
                                cache: true
                                visible: shouldAnimate && status === AnimatedImage.Ready
                            }

                            MouseArea {
                                id: gifMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedIndex = index
                                    root.executeSelected()
                                }
                                onEntered: root.selectedIndex = index
                            }
                        }
                    }
                }
            }
        }
    }
}
