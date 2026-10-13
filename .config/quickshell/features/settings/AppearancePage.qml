
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.features.settings
import qs.core

SettingsScrollPage {
    id: root
    spacing: 16

        SettingsSection {
            title: "Glass"
            subtitle: "Frosted panel fill used by cards, settings, and calendar"

            SettingsSlider {
                label: "Opacity"
                key: "glassOpacity"
                from: 0.15
                to: 0.9
                stepSize: 0.01
                defaultValue: 0.45
            }

            SettingsSlider {
                label: "Tint strength"
                key: "glassTintStrength"
                from: 0
                to: 0.4
                stepSize: 0.01
                defaultValue: 0.14
            }

            SettingsSlider {
                label: "Border opacity"
                key: "glassBorderOpacity"
                from: 0.04
                to: 0.4
                stepSize: 0.01
                defaultValue: 0.16
            }
        }

        SettingsSection {
            title: "Surfaces"
            subtitle: "Solid chrome / bar fill behind glass overlays"

            SettingsSlider {
                label: "Surface transparency"
                key: "surfaceTransparency"
                from: 0.2
                to: 1.0
                stepSize: 0.05
                defaultValue: 0.6
            }

            SettingsSlider {
                label: "Card corner radius"
                key: "cardRadius"
                suffix: "px"
                from: 4
                to: 28
                stepSize: 1
                defaultValue: 12
            }
        }

        SettingsSection {
            title: "Shell frame"
            subtitle: "Outer blob border around the desktop (not niri window corners)"

            SettingsSlider {
                label: "Corner radius"
                key: "screenCornerRadius"
                suffix: "px"
                from: 0
                to: 48
                stepSize: 1
                defaultValue: 24
            }

            SettingsSlider {
                label: "Border width"
                key: "screenBorderWidth"
                suffix: "px"
                from: 0
                to: 16
                stepSize: 1
                defaultValue: 6
            }

            SettingsSlider {
                label: "Blob smoothing"
                key: "screenSmoothing"
                from: 0
                to: 40
                stepSize: 1
                defaultValue: 20
            }
        }

        SettingsSection {
            title: "Bar"
            subtitle: "Top chrome height"

            SettingsSlider {
                label: "Height"
                key: "barHeight"
                suffix: "px"
                from: 24
                to: 48
                stepSize: 1
                defaultValue: 30
            }
        }

        SettingsSection {
            title: "Theme"
            subtitle: "Matugen palette for the whole desktop"

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: 12
                    color: Theme.withAlpha(Theme.accent, 0.2)
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.accent, 0.45)

                    Text {
                        anchors.centerIn: parent
                        text: MatugenPreferences.schemeName
                        color: Theme.accent
                        font.family: Settings.fontFamilyDefault
                        font.pixelSize: Settings.fontSizeMedium
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            MatugenPreferences.nextScheme();
                            if (Settings.backgroundImagePath)
                                MatugenRunner.run(Settings.backgroundImagePath);
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: 40
                    radius: 12
                    color: Theme.withAlpha(Theme.textPrimary, 0.08)
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.textPrimary, 0.12)

                    Text {
                        anchors.centerIn: parent
                        text: MatugenPreferences.colorMode === "dark" ? "Dark" : "Light"
                        color: Theme.textPrimary
                        font.family: Settings.fontFamilyDefault
                        font.pixelSize: Settings.fontSizeMedium
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            MatugenPreferences.toggleMode();
                            if (Settings.backgroundImagePath)
                                MatugenRunner.run(Settings.backgroundImagePath);
                        }
                    }
                }
            }

            SettingsSlider {
                label: "Contrast"
                valueText: MatugenPreferences.contrastLevel.toFixed(2)
                from: -1
                to: 1
                stepSize: 0.05
                value: MatugenPreferences.contrastLevel
                defaultValue: 0
                onMoved: v => {
                    MatugenPreferences.setContrast(v);
                    if (Settings.backgroundImagePath)
                        MatugenRunner.run(Settings.backgroundImagePath);
                }
            }
        }
}
