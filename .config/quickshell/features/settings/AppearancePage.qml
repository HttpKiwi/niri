
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
                valueText: Settings.glassOpacity.toFixed(2)
                from: 0.15
                to: 0.9
                stepSize: 0.01
                value: Settings.glassOpacity
                defaultValue: 0.45
                onMoved: v => Settings.setPref("glassOpacity", v)
            }

            SettingsSlider {
                label: "Tint strength"
                valueText: Settings.glassTintStrength.toFixed(2)
                from: 0
                to: 0.4
                stepSize: 0.01
                value: Settings.glassTintStrength
                defaultValue: 0.14
                onMoved: v => Settings.setPref("glassTintStrength", v)
            }

            SettingsSlider {
                label: "Border opacity"
                valueText: Settings.glassBorderOpacity.toFixed(2)
                from: 0.04
                to: 0.4
                stepSize: 0.01
                value: Settings.glassBorderOpacity
                defaultValue: 0.16
                onMoved: v => Settings.setPref("glassBorderOpacity", v)
            }
        }

        SettingsSection {
            title: "Surfaces"
            subtitle: "Solid chrome / bar fill behind glass overlays"

            SettingsSlider {
                label: "Surface transparency"
                valueText: Settings.surfaceTransparency.toFixed(2)
                from: 0.2
                to: 1.0
                stepSize: 0.05
                value: Settings.surfaceTransparency
                defaultValue: 0.6
                onMoved: v => Settings.setPref("surfaceTransparency", v)
            }

            SettingsSlider {
                label: "Card corner radius"
                valueText: `${Settings.cardRadius}px`
                from: 4
                to: 28
                stepSize: 1
                value: Settings.cardRadius
                defaultValue: 12
                onMoved: v => Settings.setPref("cardRadius", Math.round(v))
            }
        }

        SettingsSection {
            title: "Shell frame"
            subtitle: "Outer blob border around the desktop (not niri window corners)"

            SettingsSlider {
                label: "Corner radius"
                valueText: `${Settings.screenCornerRadius}px`
                from: 0
                to: 48
                stepSize: 1
                value: Settings.screenCornerRadius
                defaultValue: 24
                onMoved: v => Settings.setPref("screenCornerRadius", Math.round(v))
            }

            SettingsSlider {
                label: "Border width"
                valueText: `${Settings.screenBorderWidth}px`
                from: 0
                to: 16
                stepSize: 1
                value: Settings.screenBorderWidth
                defaultValue: 6
                onMoved: v => Settings.setPref("screenBorderWidth", Math.round(v))
            }

            SettingsSlider {
                label: "Blob smoothing"
                valueText: `${Settings.screenSmoothing}`
                from: 0
                to: 40
                stepSize: 1
                value: Settings.screenSmoothing
                defaultValue: 20
                onMoved: v => Settings.setPref("screenSmoothing", Math.round(v))
            }
        }

        SettingsSection {
            title: "Bar"
            subtitle: "Top chrome height"

            SettingsSlider {
                label: "Height"
                valueText: `${Settings.barHeight}px`
                from: 24
                to: 48
                stepSize: 1
                value: Settings.barHeight
                defaultValue: 30
                onMoved: v => Settings.setPref("barHeight", Math.round(v))
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
