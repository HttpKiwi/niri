
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.features.settings

SettingsScrollPage {
    id: root
    spacing: 22

        SettingsSection {
            title: "Idle & lock"
            subtitle: "Auto-lock and sleep while the session is idle"

            SettingsToggle {
                label: "Auto lock"
                description: `Locks after ${Settings.idleLockTimeout}s idle`
                checked: Settings.enableAutoLock
                onToggled: v => Settings.setPref("enableAutoLock", v)
            }

            SettingsToggle {
                label: "Auto sleep"
                description: "Suspend after lock timeout + sleep delay"
                checked: Settings.enableAutoSleep
                onToggled: v => Settings.setPref("enableAutoSleep", v)
            }

            SettingsToggle {
                label: "Inhibit while media plays"
                description: "Skip idle lock/sleep when an MPRIS player is playing"
                checked: Settings.inhibitIdleWhenAudio
                onToggled: v => Settings.setPref("inhibitIdleWhenAudio", v)
            }

            SettingsSlider {
                label: "Lock after (seconds)"
                valueText: `${Settings.idleLockTimeout}s`
                from: 60
                to: 1800
                stepSize: 30
                value: Settings.idleLockTimeout
                defaultValue: 300
                onMoved: v => Settings.setPref("idleLockTimeout", Math.round(v))
            }

            SettingsSlider {
                label: "Sleep after lock (seconds)"
                valueText: `${Settings.idleSleepTimeout}s`
                from: 60
                to: 3600
                stepSize: 30
                value: Settings.idleSleepTimeout
                defaultValue: 600
                onMoved: v => Settings.setPref("idleSleepTimeout", Math.round(v))
            }
        }

        SettingsSection {
            title: "Notifications"
            subtitle: "Popup lifetime for new notifications"

            SettingsSlider {
                label: "Timeout"
                valueText: `${Math.round(Settings.notificationTimeout / 1000)}s`
                from: 2000
                to: 15000
                stepSize: 500
                value: Settings.notificationTimeout
                defaultValue: 5000
                onMoved: v => Settings.setPref("notificationTimeout", Math.round(v))
            }
        }

        SettingsSection {
            title: "Screen record"
            subtitle: "gpu-screen-recorder defaults"

            SettingsSlider {
                label: "FPS"
                valueText: `${Settings.screenRecordFps}`
                from: 30
                to: 144
                stepSize: 6
                value: Settings.screenRecordFps
                defaultValue: 60
                onMoved: v => Settings.setPref("screenRecordFps", Math.round(v))
            }
        }

        SettingsSection {
            title: "Motion"
            subtitle: "Animation durations used by panels and indicators"

            SettingsSlider {
                label: "Short"
                valueText: `${Settings.animationDurationShort}ms`
                from: 50
                to: 400
                stepSize: 10
                value: Settings.animationDurationShort
                defaultValue: 150
                onMoved: v => Settings.setPref("animationDurationShort", Math.round(v))
            }

            SettingsSlider {
                label: "Medium"
                valueText: `${Settings.animationDurationMedium}ms`
                from: 100
                to: 600
                stepSize: 10
                value: Settings.animationDurationMedium
                defaultValue: 250
                onMoved: v => Settings.setPref("animationDurationMedium", Math.round(v))
            }

            SettingsSlider {
                label: "Long"
                valueText: `${Settings.animationDurationLong}ms`
                from: 200
                to: 900
                stepSize: 20
                value: Settings.animationDurationLong
                defaultValue: 400
                onMoved: v => Settings.setPref("animationDurationLong", Math.round(v))
            }
        }

        SettingsSection {
            title: "Animated wallpapers"
            subtitle: "Video / GIF playback on all monitors. Pauses while locked."

            SettingsToggle {
                label: "Enable animated wallpapers"
                description: "Play mp4/webm/gif/webp; pause while locked"
                checked: Settings.animatedWallpapersEnabled
                onToggled: v => Settings.setPref("animatedWallpapersEnabled", v)
            }
        }

        SettingsSection {
            title: "Blur"
            subtitle: "Quickshell window blur helpers (niri blur is under Niri)"

            SettingsToggle {
                label: "Shell blur enabled"
                checked: Settings.blurEnabled
                onToggled: v => Settings.setPref("blurEnabled", v)
            }

            SettingsSlider {
                label: "Blur border opacity"
                valueText: Settings.blurBorderOpacity.toFixed(2)
                from: 0.1
                to: 0.8
                stepSize: 0.05
                value: Settings.blurBorderOpacity
                defaultValue: 0.35
                onMoved: v => Settings.setPref("blurBorderOpacity", v)
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
