
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
                valueText: Settings.chromeIntensity.toFixed(2)
                from: 0
                to: 1.5
                stepSize: 0.05
                value: Settings.chromeIntensity
                defaultValue: 1
                onMoved: v => Settings.setPref("chromeIntensity", v)
            }

            SettingsSlider {
                label: "Anim speed"
                valueText: Settings.chromeAnimSpeed.toFixed(2)
                from: 0.05
                to: 1.0
                stepSize: 0.05
                value: Settings.chromeAnimSpeed
                defaultValue: 0.2
                onMoved: v => Settings.setPref("chromeAnimSpeed", v)
            }

            SettingsSlider {
                label: "Cell size"
                valueText: Settings.chromeCellSize.toFixed(1)
                from: 2
                to: 12
                stepSize: 0.5
                value: Settings.chromeCellSize
                defaultValue: 5
                onMoved: v => Settings.setPref("chromeCellSize", v)
            }

            SettingsSlider {
                label: "Dot size"
                valueText: Settings.chromeDotSize.toFixed(2)
                from: 0.1
                to: 0.8
                stepSize: 0.05
                value: Settings.chromeDotSize
                defaultValue: 0.35
                onMoved: v => Settings.setPref("chromeDotSize", v)
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
}
