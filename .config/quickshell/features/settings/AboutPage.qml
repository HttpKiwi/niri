
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.core
import qs.features.settings

SettingsScrollPage {
    id: root
    spacing: 16

        Text {
            text: "About"
            color: Theme.textPrimary
            font.family: Settings.fontFamilyDefault
            font.pixelSize: Settings.fontSizeTitle
            font.weight: Font.Bold
        }

        Text {
            Layout.fillWidth: true
            text: "Niri + Quickshell settings. Shell prefs save to common/shell-prefs.json. Niri changes write config.kdl after validate."
            color: Theme.textSecondary
            font.family: Settings.fontFamilyDefault
            font.pixelSize: Settings.fontSizeMedium
            wrapMode: Text.Wrap
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: aboutCol.implicitHeight + 24
            radius: Settings.cardRadius
            color: Theme.withAlpha(Theme.textPrimary, 0.06)
            border.width: 1
            border.color: Theme.withAlpha(Theme.textPrimary, 0.1)

            ColumnLayout {
                id: aboutCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 8

                Text {
                    text: `User: ${Settings.username}`
                    color: Theme.textPrimary
                    font.family: Settings.fontFamilyDefault
                    font.pixelSize: Settings.fontSizeMedium
                }
                Text {
                    Layout.fillWidth: true
                    text: `Shell: ${Quickshell.shellDir}`
                    color: Theme.textSecondary
                    font.family: Settings.fontFamilyDefault
                    font.pixelSize: Settings.fontSizeSmall
                    elide: Text.ElideMiddle
                }
                Text {
                    Layout.fillWidth: true
                    text: `Prefs: ${Settings.shellPrefsFile}`
                    color: Theme.textSecondary
                    font.family: Settings.fontFamilyDefault
                    font.pixelSize: Settings.fontSizeSmall
                    elide: Text.ElideMiddle
                }
                Text {
                    Layout.fillWidth: true
                    text: `Niri: ${NiriConfig.configPath || "~/.config/niri/config.kdl"}`
                    color: Theme.textSecondary
                    font.family: Settings.fontFamilyDefault
                    font.pixelSize: Settings.fontSizeSmall
                    elide: Text.ElideMiddle
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Open with Super+I or: qs ipc call settings toggle"
            color: Theme.textSecondary
            font.family: Settings.fontFamilyDefault
            font.pixelSize: Settings.fontSizeSmall
            wrapMode: Text.Wrap
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
