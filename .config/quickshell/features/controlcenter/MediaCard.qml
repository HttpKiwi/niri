import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs.config
import qs.core

/**
 * MediaCard - MPRIS media player card
 * Shows album art, track info, playback controls, and progress
 */
Rectangle {
    id: root

    property real _safeLength: 0
    property string _safeTrackId: ""
    property var _activePlayer: Players.active
    readonly property int contentPadding: 10

    on_ActivePlayerChanged: {
        _safeLength = 0;
        _safeTrackId = "";
        updateSafeLength();
    }

    function updateSafeLength() {
        const active = Players.active;
        if (!active) {
            _safeLength = 0;
            _safeTrackId = "";
            return;
        }

        const len = active.length || 0;
        const tid = (active.metadata && active.metadata["mpris:trackid"])
            ? String(active.metadata["mpris:trackid"])
            : ((active.trackTitle ?? "") + "|" + (active.trackArtist ?? "") + "|" + (active.trackAlbum ?? ""));

        if (tid !== _safeTrackId) {
            _safeTrackId = tid;
            if (len > 0) _safeLength = len;
            return;
        }

        if (len > _safeLength) {
            _safeLength = len;
        }
    }

    property real playerProgress: {
        const active = Players.active;
        if (_safeLength <= 0) return 0;
        return (active?.position ?? 0) / _safeLength;
    }

    Timer {
        id: posTimer
        running: Players.active !== null
        interval: Players.active?.isPlaying ? 500 : 2000
        triggeredOnStart: true
        repeat: true
        onTriggered: {
            Players.active?.positionChanged();
            root.updateSafeLength();
        }
    }

    implicitHeight: mediaContent.implicitHeight + contentPadding * 2
    width: parent ? parent.width : 380
    radius: Settings.cardRadius
    color: Theme.glass(Settings.glassOpacity, Settings.glassTintStrength)
    border.color: Theme.glassBorder(Settings.glassBorderOpacity, Settings.glassTintStrength)
    border.width: Settings.cardBorderWidth
    antialiasing: true

    Column {
        id: mediaContent
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: root.contentPadding
        }
        spacing: 8

        // Album art row
        RowLayout {
            width: parent.width
            spacing: 10
            visible: Players.active !== null

            // Album art
            Rectangle {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 48
                radius: 8
                color: Theme.surfaceHighest
                clip: true

                Image {
                    id: albumArt
                    anchors.fill: parent
                    source: Players.getArtUrl(Players.active)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                }

                Text {
                    anchors.centerIn: parent
                    text: "\ue250"
                    color: Theme.textDisabled
                    font.family: Settings.fontFamilyIcons
                    font.pixelSize: 20
                    visible: albumArt.status !== Image.Ready
                }
            }

            // Track info
            Column {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    width: parent.width
                    text: Players.active?.identity ?? ""
                    color: Theme.accent
                    font.family: Settings.fontFamilyDefault
                    font.pixelSize: Settings.fontSizeSmall
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: Players.active?.trackTitle || "No media playing"
                    color: Theme.textPrimary
                    font.family: Settings.fontFamilyDefault
                    font.pixelSize: Settings.fontSizeLarge
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    wrapMode: Text.NoWrap
                }

                Text {
                    width: parent.width
                    text: Players.active?.trackArtist || ""
                    color: Theme.textSecondary
                    font.family: Settings.fontFamilyDefault
                    font.pixelSize: Settings.fontSizeSmall
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    wrapMode: Text.NoWrap
                    visible: text.length > 0
                }

            }
        }

        // Empty state
        Item {
            width: parent.width
            height: 40
            visible: Players.active === null

            Text {
                anchors.centerIn: parent
                text: "No media playing"
                color: Theme.textSecondary
                font.family: Settings.fontFamilyDefault
                font.pixelSize: Settings.fontSizeSmall
            }
        }

        // Player selector
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 4
            visible: Players.active !== null

            Repeater {
                model: Players.list

                delegate: Rectangle {
                    required property MprisPlayer modelData

                    width: playerLabel.implicitWidth + 14
                    height: 22
                    radius: 11
                    color: modelData === Players.active ? Theme.accent : Theme.surfaceHighest

                    Behavior on color {
                        ColorAnimation { duration: Settings.animationDurationShort }
                    }

                    Text {
                        id: playerLabel
                        anchors.centerIn: parent
                        text: Players.getIdentity(modelData)
                        color: modelData === Players.active ? Theme.textOnPrimary : Theme.textPrimary
                        font.family: Settings.fontFamilyDefault
                        font.pixelSize: Settings.fontSizeCaption
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Players.manualActive = modelData
                    }
                }
            }
        }

        // Playback controls
        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            visible: Players.active !== null

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 28
                height: 28
                radius: 14
                color: prevHover.hovered ? Theme.accentContainer : "transparent"
                opacity: Players.active?.canGoPrevious ? 1 : 0.3

                Behavior on color {
                    ColorAnimation { duration: Settings.animationDurationShort }
                }

                Text {
                    anchors.centerIn: parent
                    text: "\ue045"
                    color: prevHover.hovered ? Theme.textOnPrimaryContainer : Theme.textPrimary
                    font.family: Settings.fontFamilyIcons
                    font.pixelSize: 16
                }

                MouseArea {
                    id: prevHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: Players.active?.canGoPrevious ?? false
                    onClicked: Players.previous()
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 34
                height: 34
                radius: 17
                color: playHover.hovered ? Theme.accentContainer : Theme.accent
                opacity: Players.active?.canTogglePlaying ? 1 : 0.3

                Behavior on color {
                    ColorAnimation { duration: Settings.animationDurationShort }
                }

                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 1
                    text: Players.active?.isPlaying ? "\ue034" : "\ue037"
                    color: Theme.textOnPrimary
                    font.family: Settings.fontFamilyIcons
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                MouseArea {
                    id: playHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: Players.active?.canTogglePlaying ?? false
                    onClicked: Players.togglePlaying()
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 28
                height: 28
                radius: 14
                color: nextHover.hovered ? Theme.accentContainer : "transparent"
                opacity: Players.active?.canGoNext ? 1 : 0.3

                Behavior on color {
                    ColorAnimation { duration: Settings.animationDurationShort }
                }

                Text {
                    anchors.centerIn: parent
                    text: "\ue044"
                    color: nextHover.hovered ? Theme.textOnPrimaryContainer : Theme.textPrimary
                    font.family: Settings.fontFamilyIcons
                    font.pixelSize: 16
                }

                MouseArea {
                    id: nextHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: Players.active?.canGoNext ?? false
                    onClicked: Players.next()
                }
            }
        }

        // Progress bar
        Column {
            width: parent.width
            spacing: 2
            visible: Players.active !== null

            Slider {
                id: progressSlider
                width: parent.width
                height: 16
                from: 0
                to: 1
                stepSize: 0.001

                background: Item {
                    x: progressSlider.leftPadding
                    y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                    width: progressSlider.availableWidth
                    height: 4

                    Rectangle {
                        width: progressSlider.visualPosition * parent.width
                        height: parent.height
                        radius: 2
                        color: Theme.accent
                    }

                    Rectangle {
                        x: progressSlider.visualPosition * parent.width
                        width: parent.width - x
                        height: parent.height
                        radius: 2
                        color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.3)
                    }
                }

                handle: Rectangle {
                    x: progressSlider.leftPadding + progressSlider.visualPosition * (progressSlider.availableWidth - width)
                    y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                    width: 12
                    height: 12
                    radius: 6
                    color: Theme.accent
                    opacity: progressSlider.hovered || progressSlider.pressed ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: Settings.animationDurationShort }
                    }
                }

                Binding {
                    target: progressSlider
                    property: "value"
                    value: root.playerProgress
                    when: !progressSlider.pressed
                }

                onMoved: {
                    const active = Players.active;
                    const len = _safeLength > 0 ? _safeLength : (active?.length || 0);
                    if (active?.canSeek && active?.positionSupported)
                        active.position = value * len;
                }
            }

            // Time display
            Item {
                width: parent.width
                height: Math.max(positionText.implicitHeight, lengthText.implicitHeight)

                Text {
                    id: positionText
                    anchors.left: parent.left
                    text: lengthStr(Players.active?.position ?? -1)
                    color: Theme.textSecondary
                    font.family: Settings.fontFamilyDefault
                    font.pixelSize: Settings.fontSizeCaption
                }

                Text {
                    id: lengthText
                    anchors.right: parent.right
                    text: lengthStr(_safeLength > 0 ? _safeLength : -1)
                    color: Theme.textSecondary
                    font.family: Settings.fontFamilyDefault
                    font.pixelSize: Settings.fontSizeCaption
                }
            }
        }
    }

    function lengthStr(length: int): string {
        if (length < 0) return "–:––";
        const hours = Math.floor(length / 3600);
        const mins = Math.floor((length % 3600) / 60);
        const secs = Math.floor(length % 60);
        const secStr = secs < 10 ? "0" + secs : String(secs);
        if (hours > 0)
            return hours + ":" + (mins < 10 ? "0" + mins : String(mins)) + ":" + secStr;
        return mins + ":" + secStr;
    }
}
