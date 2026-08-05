pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.core
import qs.components.base
import qs.features.settings

/**
 * SettingsPanel - Top-pinned pocket (launcher/wallpaper pattern, from the bar).
 */
PocketTopPanel {
    id: root

    panelFlag: "settings"
    topInset: 8
    animationDuration: Settings.animationDurationMedium
    easingType: Settings.easingStandard

    property string screenName: ""
    property real screenWidth: 0
    property real screenHeight: 0

    property int currentPage: 0
    readonly property var pages: [
        { key: "appearance", label: "Appearance", icon: "\ue3ae" },
        { key: "chrome", label: "Chrome", icon: "\ue3a0" },
        { key: "shell", label: "Shell", icon: "\ue8b8" },
        { key: "niri", label: "Niri", icon: "\ue871" },
        { key: "about", label: "About", icon: "\ue88e" }
    ]

    readonly property int panelW: Math.min(920, Math.max(640, Math.round(screenWidth - Settings.screenBorderWidth * 2 - 48)))
    readonly property int panelH: Math.min(620, Math.max(420, Math.round(screenHeight * 0.62)))

    implicitWidth: panelW
    implicitHeight: panelH
    width: panelW
    height: panelH

    onOpened: {
        NiriConfig.refresh();
        Qt.callLater(() => keyboardScope.forceActiveFocus());
    }

    FocusScope {
        id: keyboardScope
        anchors.fill: parent
        anchors.margins: 14
        anchors.topMargin: 12
        focus: root.shouldBeActive

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                if (root.panelState)
                    root.panelState.settings = false;
                event.accepted = true;
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 200
                Layout.fillHeight: true
                radius: Settings.cardRadius
                color: Theme.glass(Math.max(Settings.glassOpacity, 0.6), Settings.glassTintStrength)
                border.width: 1
                border.color: Theme.glassBorder(Settings.glassBorderOpacity, Settings.glassTintStrength)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6

                    Text {
                        text: "Settings"
                        color: Theme.textPrimary
                        font.family: Settings.fontFamilyDefault
                        font.pixelSize: Settings.fontSizeTitle
                        font.weight: Font.Bold
                        Layout.bottomMargin: 8
                    }

                    Repeater {
                        model: root.pages

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool selected: root.currentPage === index

                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            radius: 10
                            color: selected
                                ? Theme.withAlpha(Theme.accent, 0.28)
                                : (navMa.containsMouse ? Theme.withAlpha(Theme.textPrimary, 0.08) : "transparent")

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                spacing: 10

                                Text {
                                    text: modelData.icon
                                    color: selected ? Theme.accent : Theme.textSecondary
                                    font.family: Settings.fontFamilyIcons
                                    font.pixelSize: 18
                                }

                                Text {
                                    text: modelData.label
                                    color: selected ? Theme.accent : Theme.textPrimary
                                    font.family: Settings.fontFamilyDefault
                                    font.pixelSize: Settings.fontSizeMedium
                                    font.weight: selected ? Font.DemiBold : Font.Normal
                                }
                            }

                            MouseArea {
                                id: navMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.currentPage = index
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Text {
                        Layout.fillWidth: true
                        text: "Super+I · Esc"
                        color: Theme.textSecondary
                        font.family: Settings.fontFamilyDefault
                        font.pixelSize: Settings.fontSizeCaption
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Settings.cardRadius
                color: Theme.glass(Math.min(0.78, Settings.glassOpacity + 0.28), Settings.glassTintStrength)
                border.width: 1
                border.color: Theme.glassBorder(Settings.glassBorderOpacity, Settings.glassTintStrength)
                clip: true

                StackLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    currentIndex: root.currentPage

                    AppearancePage {}
                    ChromePage {}
                    ShellPage {}
                    NiriPage {}
                    AboutPage {}
                }
            }
        }
    }
}
