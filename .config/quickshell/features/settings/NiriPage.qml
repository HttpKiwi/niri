
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.features.settings
import qs.core

SettingsScrollPage {
    id: root
    spacing: 22

        SettingsSection {
            title: "Layout"
            subtitle: "Writes to config.kdl · validated before keeping"

            SettingsSlider {
                label: "Gaps"
                valueText: `${NiriConfig.gaps}px`
                from: 0
                to: 48
                stepSize: 1
                value: NiriConfig.gaps
                defaultValue: 12
                onMoved: v => NiriConfig.setGaps(v)
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "Center focused column"
                    color: Theme.textPrimary
                    font.family: Settings.fontFamilyDefault
                    font.pixelSize: Settings.fontSizeMedium
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: [
                            { value: "never", label: "Never" },
                            { value: "always", label: "Always" },
                            { value: "on-overflow", label: "Overflow" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool active: NiriConfig.centerFocusedColumn === modelData.value

                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            radius: 10
                            color: active
                                ? Theme.withAlpha(Theme.accent, 0.28)
                                : Theme.withAlpha(Theme.textPrimary, 0.08)
                            border.width: 1
                            border.color: active
                                ? Theme.withAlpha(Theme.accent, 0.45)
                                : Theme.withAlpha(Theme.textPrimary, 0.1)

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: active ? Theme.accent : Theme.textPrimary
                                font.family: Settings.fontFamilyDefault
                                font.pixelSize: Settings.fontSizeSmall
                                font.weight: active ? Font.DemiBold : Font.Normal
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NiriConfig.setCenterFocusedColumn(modelData.value)
                            }
                        }
                    }
                }
            }

            SettingsSlider {
                label: "Focus ring width"
                valueText: `${NiriConfig.focusRingWidth}px`
                from: 0
                to: 9
                stepSize: 1
                value: NiriConfig.focusRingWidth
                defaultValue: 0
                onMoved: v => NiriConfig.setFocusRingWidth(v)
            }
        }

        SettingsSection {
            title: "Windows"
            subtitle: "Default window-rule geometry and inactive look"

            SettingsSlider {
                label: "Window corner radius"
                valueText: `${NiriConfig.cornerRadius}px`
                from: 0
                to: 40
                stepSize: 1
                value: NiriConfig.cornerRadius
                defaultValue: 18
                onMoved: v => NiriConfig.setCornerRadius(v)
            }

            Text {
                Layout.fillWidth: true
                text: "geometry-corner-radius on windows — not the shell frame (Appearance → Look & feel)"
                color: Theme.textSecondary
                font.family: Settings.fontFamilyDefault
                font.pixelSize: Settings.fontSizeCaption
                wrapMode: Text.Wrap
            }

            SettingsToggle {
                label: "Clip to geometry"
                description: "Round window contents to the corner radius"
                checked: NiriConfig.clipToGeometry
                onToggled: v => NiriConfig.setClipToGeometry(v)
            }

            SettingsSlider {
                label: "Inactive opacity"
                valueText: NiriConfig.inactiveOpacity.toFixed(2)
                from: 0.5
                to: 1.0
                stepSize: 0.05
                value: NiriConfig.inactiveOpacity
                defaultValue: 0.9
                onMoved: v => NiriConfig.setInactiveOpacity(v)
            }

            SettingsToggle {
                label: "Prefer no CSD"
                description: "Ask clients to skip client-side decorations"
                checked: NiriConfig.preferNoCsd
                onToggled: v => NiriConfig.setPreferNoCsd(v)
            }
        }

        SettingsSection {
            title: "Input"
            subtitle: "Pointer focus behavior"

            SettingsToggle {
                label: "Focus follows mouse"
                checked: NiriConfig.focusFollowsMouse
                onToggled: v => NiriConfig.setFocusFollowsMouse(v)
            }

            SettingsSlider {
                label: "FFM max scroll"
                valueText: `${NiriConfig.ffmMaxScrollPercent}%`
                from: 10
                to: 100
                stepSize: 5
                value: NiriConfig.ffmMaxScrollPercent
                defaultValue: 80
                enabled: NiriConfig.focusFollowsMouse
                opacity: enabled ? 1 : 0.45
                onMoved: v => NiriConfig.setFfmMaxScrollPercent(v)
            }

            SettingsToggle {
                label: "Warp mouse to focus"
                description: "Move cursor onto newly focused windows"
                checked: NiriConfig.warpMouseToFocus
                onToggled: v => NiriConfig.setWarpMouseToFocus(v)
            }

            SettingsToggle {
                label: "Skip hotkey overlay at startup"
                checked: NiriConfig.hotkeyOverlaySkip
                onToggled: v => NiriConfig.setHotkeyOverlaySkip(v)
            }
        }

        SettingsSection {
            title: "Cursor"
            subtitle: `Theme: ${NiriConfig.cursorTheme}`

            SettingsSlider {
                label: "Cursor size"
                valueText: `${NiriConfig.cursorSize}px`
                from: 16
                to: 48
                stepSize: 2
                value: NiriConfig.cursorSize
                defaultValue: 24
                onMoved: v => NiriConfig.setCursorSize(v)
            }
        }

        SettingsSection {
            title: "Overview"
            subtitle: "Workspace overview zoom"

            SettingsSlider {
                label: "Zoom"
                valueText: NiriConfig.overviewZoom.toFixed(2)
                from: 0.2
                to: 0.8
                stepSize: 0.05
                value: NiriConfig.overviewZoom
                defaultValue: 0.4
                onMoved: v => NiriConfig.setOverviewZoom(v)
            }
        }

        SettingsSection {
            title: "Animations"
            subtitle: "Compositor motion (springs + slowdown)"

            SettingsToggle {
                label: "Enable animations"
                checked: NiriConfig.animationsEnabled
                onToggled: v => NiriConfig.setAnimationsEnabled(v)
            }

            SettingsSlider {
                label: "Slowdown"
                valueText: NiriConfig.animationsSlowdown.toFixed(1)
                from: 0.1
                to: 3.0
                stepSize: 0.1
                value: NiriConfig.animationsSlowdown
                defaultValue: 1.0
                enabled: NiriConfig.animationsEnabled
                opacity: enabled ? 1 : 0.45
                onMoved: v => NiriConfig.setAnimationsSlowdown(v)
            }

            SettingsSlider {
                label: "Workspace switch damping"
                valueText: NiriConfig.workspaceSwitchDamping.toFixed(2)
                from: 0.5
                to: 1.0
                stepSize: 0.05
                value: NiriConfig.workspaceSwitchDamping
                defaultValue: 0.85
                enabled: NiriConfig.animationsEnabled
                opacity: enabled ? 1 : 0.45
                onMoved: v => NiriConfig.setWorkspaceSwitchDamping(v)
            }

            SettingsSlider {
                label: "Workspace switch stiffness"
                valueText: `${NiriConfig.workspaceSwitchStiffness}`
                from: 200
                to: 1600
                stepSize: 50
                value: NiriConfig.workspaceSwitchStiffness
                defaultValue: 800
                enabled: NiriConfig.animationsEnabled
                opacity: enabled ? 1 : 0.45
                onMoved: v => NiriConfig.setWorkspaceSwitchStiffness(v)
            }

            SettingsSlider {
                label: "Overview anim damping"
                valueText: NiriConfig.overviewAnimDamping.toFixed(2)
                from: 0.5
                to: 1.0
                stepSize: 0.05
                value: NiriConfig.overviewAnimDamping
                defaultValue: 0.8
                enabled: NiriConfig.animationsEnabled
                opacity: enabled ? 1 : 0.45
                onMoved: v => NiriConfig.setOverviewAnimDamping(v)
            }

            SettingsSlider {
                label: "Overview anim stiffness"
                valueText: `${NiriConfig.overviewAnimStiffness}`
                from: 200
                to: 1600
                stepSize: 50
                value: NiriConfig.overviewAnimStiffness
                defaultValue: 800
                enabled: NiriConfig.animationsEnabled
                opacity: enabled ? 1 : 0.45
                onMoved: v => NiriConfig.setOverviewAnimStiffness(v)
            }
        }

        SettingsSection {
            title: "Blur"
            subtitle: "Compositor backdrop blur (niri blur { })"

            SettingsSlider {
                label: "Passes"
                valueText: `${NiriConfig.blurPasses}`
                from: 1
                to: 8
                stepSize: 1
                value: NiriConfig.blurPasses
                defaultValue: 4
                onMoved: v => NiriConfig.setBlurPasses(v)
            }

            SettingsSlider {
                label: "Noise"
                valueText: NiriConfig.blurNoise.toFixed(3)
                from: 0
                to: 0.1
                stepSize: 0.005
                value: NiriConfig.blurNoise
                defaultValue: 0.01
                onMoved: v => NiriConfig.setBlurNoise(v)
            }

            SettingsSlider {
                label: "Saturation"
                valueText: NiriConfig.blurSaturation.toFixed(2)
                from: 0.5
                to: 2.0
                stepSize: 0.05
                value: NiriConfig.blurSaturation
                defaultValue: 1.2
                onMoved: v => NiriConfig.setBlurSaturation(v)
            }

            SettingsSlider {
                label: "Offset"
                valueText: NiriConfig.blurOffset.toFixed(1)
                from: 0
                to: 5
                stepSize: 0.1
                value: NiriConfig.blurOffset
                defaultValue: 1.8
                onMoved: v => NiriConfig.setBlurOffset(v)
            }
        }

        Text {
            Layout.fillWidth: true
            visible: NiriConfig.statusMessage.length > 0
            text: NiriConfig.statusMessage
            color: NiriConfig.statusMessage.indexOf("Invalid") >= 0 ? Theme.error : Theme.textSecondary
            font.family: Settings.fontFamilyDefault
            font.pixelSize: Settings.fontSizeSmall
            wrapMode: Text.Wrap
        }

        Text {
            Layout.fillWidth: true
            text: NiriConfig.configPath
            color: Theme.textSecondary
            font.family: Settings.fontFamilyDefault
            font.pixelSize: Settings.fontSizeCaption
            elide: Text.ElideMiddle
        }
}
