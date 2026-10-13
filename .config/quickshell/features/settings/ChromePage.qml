
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.features.settings

SettingsScrollPage {
    id: root
    spacing: 22

        SettingsSection {
            title: "Blob chrome"
            subtitle: "Aurora shader on the bar frame and this window. Changes apply live."

            SettingsToggle {
                label: "Enable chrome shader"
                description: "Dot-matrix aurora driven by matugen colors"
                checked: Settings.chromeShaderEnabled
                onToggled: v => Settings.setPref("chromeShaderEnabled", v)
            }

            SettingsSlider {
                label: "Intensity"
                key: "chromeIntensity"
                from: 0
                to: 1.5
                stepSize: 0.05
                defaultValue: 1
            }

            SettingsSlider {
                label: "Anim speed"
                key: "chromeAnimSpeed"
                from: 0.05
                to: 1.0
                stepSize: 0.05
                defaultValue: 0.2
            }

            SettingsSlider {
                label: "Cell size"
                key: "chromeCellSize"
                from: 2
                to: 12
                stepSize: 0.5
                defaultValue: 5
            }

            SettingsSlider {
                label: "Dot size"
                key: "chromeDotSize"
                from: 0.1
                to: 0.8
                stepSize: 0.05
                defaultValue: 0.35
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
}
