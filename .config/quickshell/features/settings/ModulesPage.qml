
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.features.settings

SettingsScrollPage {
    id: root
    spacing: 16

        SettingsSection {
            title: "Left · Navigation"
            subtitle: "Workspace switcher on the left side of the bar"

            SettingsToggle {
                label: "Workspaces"
                description: "Pills for each workspace on this monitor"
                checked: Settings.showBarWorkspaces
                onToggled: v => Settings.setPref("showBarWorkspaces", v)
            }

            SettingsToggle {
                label: "Workspace minimap"
                description: "Tiny layout of the active workspace's columns"
                checked: Settings.showBarMinimap
                onToggled: v => Settings.setPref("showBarMinimap", v)
            }
        }

        SettingsSection {
            title: "Center · Focus"
            subtitle: "What sits in the middle of the bar"

            SettingsToggle {
                label: "Window title"
                description: "Focused window title"
                checked: Settings.showBarTitle
                onToggled: v => Settings.setPref("showBarTitle", v)
            }
        }

        SettingsSection {
            title: "Right · System"
            subtitle: "Status indicators before date and clock"

            SettingsToggle {
                label: "Single pill"
                description: "One shared pill behind all right-side modules"
                checked: Settings.barMergedPills
                onToggled: v => Settings.setPref("barMergedPills", v)
            }

            SettingsToggle {
                label: "Volume"
                description: "Mute toggle and scroll to change volume"
                checked: Settings.showBarVolume
                onToggled: v => Settings.setPref("showBarVolume", v)
            }

            SettingsToggle {
                label: "Screen recording"
                description: "Start / pause / stop controls"
                checked: Settings.showBarRecording
                onToggled: v => Settings.setPref("showBarRecording", v)
            }

            SettingsToggle {
                label: "Headset battery"
                description: "Battery readout from headsetcontrol"
                checked: Settings.showBarHeadset
                onToggled: v => Settings.setPref("showBarHeadset", v)
            }

            SettingsToggle {
                label: "Resources"
                description: "CPU and memory percentages"
                checked: Settings.showBarResources
                onToggled: v => Settings.setPref("showBarResources", v)
            }
        }

        SettingsSection {
            title: "Right · Clock & calendar"
            subtitle: "Date and time pills; both open the calendar"

            SettingsToggle {
                label: "Date"
                description: "Show the date pill"
                checked: Settings.showBarDate
                onToggled: v => Settings.setPref("showBarDate", v)
            }

            SettingsToggle {
                label: "Clock"
                description: "Show the time pill"
                checked: Settings.showBarTime
                onToggled: v => Settings.setPref("showBarTime", v)
            }
        }

        SettingsSection {
            title: "Clock format"
            subtitle: "How the time pill renders"

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [
                        { id: "HH:mm", label: "24-hour", sample: "14:05" },
                        { id: "hh:mm AP", label: "12-hour", sample: "2:05 PM" },
                        { id: "HH:mm:ss", label: "24-hour with seconds", sample: "14:05:09" },
                        { id: "hh:mm:ss AP", label: "12-hour with seconds", sample: "2:05:09 PM" }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool selected: Settings.barTimeFormat === modelData.id

                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: 10
                        color: selected
                            ? Theme.withAlpha(Theme.accent, 0.28)
                            : (fmtMa.containsMouse ? Theme.withAlpha(Theme.textPrimary, 0.08) : "transparent")
                        border.width: selected ? 1 : 0
                        border.color: Theme.withAlpha(Theme.accent, 0.45)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                Layout.fillWidth: true
                                text: modelData.label
                                color: selected ? Theme.accent : Theme.textPrimary
                                font.family: Settings.fontFamilyDefault
                                font.pixelSize: Settings.fontSizeMedium
                                font.weight: selected ? Font.DemiBold : Font.Normal
                            }

                            Text {
                                text: modelData.sample
                                color: Theme.textSecondary
                                font.family: Settings.fontFamilyDefault
                                font.pixelSize: Settings.fontSizeSmall
                                font.features: { "tnum": 1 }
                            }
                        }

                        MouseArea {
                            id: fmtMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Settings.setPref("barTimeFormat", modelData.id)
                        }
                    }
                }
            }
        }

        SettingsSection {
            title: "Date format"
            subtitle: "How the date pill renders"

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [
                        { id: "ddd. dd MMM", label: "Short weekday", sample: "Fri. 04 Sep" },
                        { id: "ddd MMM d", label: "Compact", sample: "Fri Sep 4" },
                        { id: "MMMM d", label: "Month day", sample: "September 4" },
                        { id: "dd/MM/yyyy", label: "Numeric", sample: "04/09/2026" }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool selected: Settings.barDateFormat === modelData.id

                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: 10
                        color: selected
                            ? Theme.withAlpha(Theme.accent, 0.28)
                            : (dateFmtMa.containsMouse ? Theme.withAlpha(Theme.textPrimary, 0.08) : "transparent")
                        border.width: selected ? 1 : 0
                        border.color: Theme.withAlpha(Theme.accent, 0.45)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                Layout.fillWidth: true
                                text: modelData.label
                                color: selected ? Theme.accent : Theme.textPrimary
                                font.family: Settings.fontFamilyDefault
                                font.pixelSize: Settings.fontSizeMedium
                                font.weight: selected ? Font.DemiBold : Font.Normal
                            }

                            Text {
                                text: modelData.sample
                                color: Theme.textSecondary
                                font.family: Settings.fontFamilyDefault
                                font.pixelSize: Settings.fontSizeSmall
                            }
                        }

                        MouseArea {
                            id: dateFmtMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Settings.setPref("barDateFormat", modelData.id)
                        }
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: Settings.prefsStatusMessage.length > 0
            text: Settings.prefsStatusMessage
            color: Theme.error
            font.family: Settings.fontFamilyDefault
            font.pixelSize: Settings.fontSizeSmall
            wrapMode: Text.Wrap
        }
}
