import QtQuick
import Quickshell.Widgets
import qs.core
import qs.config

/**
 * RecordingIndicator - Bar pill for screen recording
 * Click the icon/timer to expand pause/stop (or start when idle)
 */
WrapperMouseArea {
    id: root

    property bool expanded: false
    hoverEnabled: true

    // Click icon area only — buttons handle their own clicks
    onClicked: {
        // Ignore if a child ControlBtn handled it via expanded toggle only on left
    }

    Connections {
        target: ScreenRecord
        function onRecordingChanged() {
            if (!ScreenRecord.recording && !ScreenRecord.pending)
                root.expanded = false;
            else if (ScreenRecord.recording)
                root.expanded = true;
        }
        function onPendingChanged() {
            if (ScreenRecord.pending)
                root.expanded = true;
            else if (!ScreenRecord.recording)
                root.expanded = false;
        }
    }

    Row {
        spacing: 6

        // Status (toggle expand)
        MouseArea {
            id: statusHit
            width: statusRow.width
            height: 16
            anchors.verticalCenter: parent.verticalCenter
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded

            Row {
                id: statusRow
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    topPadding: 1
                    fontSizeMode: Text.VerticalFit
                    font.family: Settings.fontFamilyIcons
                    font.pixelSize: 14
                    color: ScreenRecord.pending
                        ? Theme.accentSecondary
                        : ScreenRecord.recording
                            ? (ScreenRecord.paused ? Theme.accentSecondary : Theme.error)
                            : Theme.textPrimary
                    text: ScreenRecord.pending ? "\ue8b8" : (ScreenRecord.recording ? "\ue061" : "\uef48")

                    SequentialAnimation on opacity {
                        running: (ScreenRecord.recording && !ScreenRecord.paused) || ScreenRecord.pending
                        loops: Animation.Infinite
                        NumberAnimation { from: 1; to: 0.25; duration: 650; easing.type: Easing.InOutQuad }
                        NumberAnimation { from: 0.25; to: 1; duration: 650; easing.type: Easing.InOutQuad }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: ScreenRecord.recording && !ScreenRecord.pending
                    color: Theme.textPrimary
                    font.family: Settings.fontFamilyDefault
                    font.pixelSize: Settings.fontSizeSmall
                    font.weight: Font.DemiBold
                    text: ScreenRecord.elapsedText
                }
            }
        }

        // Expanded controls — fixed widths avoid Pill binding loops
        Item {
            id: controls
            anchors.verticalCenter: parent.verticalCenter
            height: 18
            width: root.expanded ? controlsRow.implicitWidth : 0
            clip: true
            opacity: root.expanded ? 1 : 0

            Behavior on width {
                NumberAnimation {
                    duration: Settings.animationDurationMedium
                    easing.type: Settings.easingStandard
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: Settings.animationDurationMedium
                    easing.type: Settings.easingStandard
                }
            }

            Row {
                id: controlsRow
                spacing: 4
                height: parent.height

                ControlBtn {
                    visible: !ScreenRecord.recording && !ScreenRecord.pending
                    icon: "\ue037"
                    tipColor: Theme.accent
                    onClicked: {
                        ScreenRecord.start();
                        root.expanded = true;
                    }
                }

                ControlBtn {
                    visible: ScreenRecord.pending
                    icon: "\ue5cd"
                    tipColor: Theme.error
                    onClicked: {
                        ScreenRecord.stop();
                        root.expanded = false;
                    }
                }

                ControlBtn {
                    visible: ScreenRecord.recording && !ScreenRecord.pending
                    icon: ScreenRecord.paused ? "\ue037" : "\ue034"
                    tipColor: Theme.accentSecondary
                    onClicked: ScreenRecord.togglePause()
                }

                ControlBtn {
                    visible: ScreenRecord.recording && !ScreenRecord.pending
                    icon: "\ue047"
                    tipColor: Theme.error
                    onClicked: {
                        ScreenRecord.stop();
                        root.expanded = false;
                    }
                }
            }
        }
    }

    component ControlBtn: Item {
        id: cbtn
        property string icon: ""
        property color tipColor: Theme.accent
        signal clicked()

        width: 18
        height: 18
        // Avoid invisible hit-targets overlapping the pause/stop buttons
        enabled: visible
        opacity: visible ? 1 : 0

        Text {
            anchors.centerIn: parent
            text: cbtn.icon
            color: cbtnMa.containsMouse ? cbtn.tipColor : Theme.textPrimary
            font.family: Settings.fontFamilyIcons
            font.pixelSize: 14
        }

        MouseArea {
            id: cbtnMa
            anchors.fill: parent
            enabled: cbtn.visible
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            preventStealing: true
            onClicked: (mouse) => {
                mouse.accepted = true;
                cbtn.clicked();
            }
        }
    }
}
