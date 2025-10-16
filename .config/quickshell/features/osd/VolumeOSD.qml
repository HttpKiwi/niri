pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import qs.core
import qs.config
import qs.components.base

/**
 * VolumeOSD - Floating volume indicator
 * Shows when volume or mute state changes with smooth animations
 */
Scope {
    id: root

    // Controls OSD visibility
    property bool shouldShowOsd: false

    // Hide after delay
    Timer {
        id: hideTimer
        interval: Settings.osdTimeout
        onTriggered: root.shouldShowOsd = false
    }

    // React to audio changes
    Connections {
        target: Audio
        function onVolumeChanged() {
            root.shouldShowOsd = true
            hideTimer.restart()
        }
        function onMutedChanged() {
            root.shouldShowOsd = true
            hideTimer.restart()
        }
    }

    // Keep pipewire objects tracked so bindings stay live
    PwObjectTracker {
        objects: [ Pipewire.defaultAudioSink ]
    }

    // Floating OSD window
    Loader {
        active: true
        sourceComponent: PanelWindow {
            id: osdWindow
            
            color: "transparent"
            implicitWidth: Settings.osdWidth
            implicitHeight: Settings.osdHeight
            exclusiveZone: -1
            
            // Position at bottom-center
            anchors {
                bottom: true
            }
            
            margins {
                bottom: Settings.osdBottomMargin
                left: (osdWindow.screen?.width || 1920) / 2 - Settings.osdWidth / 2
                right: (osdWindow.screen?.width || 1920) / 2 - Settings.osdWidth / 2
            }
            
            // Mask to clip to rounded shape
            mask: Region {
                item: osdCard
            }
            
            Item {
                id: osdContainer
                anchors.fill: parent
                
                // Slide-up animation
                transform: Translate {
                    id: slideTransform
                    y: root.shouldShowOsd ? 0 : 150
                    
                    Behavior on y {
                        NumberAnimation {
                            duration: Settings.animationDurationMedium
                            easing.type: Settings.easingStandard
                        }
                    }
                }
                
                // Fade animation
                opacity: root.shouldShowOsd ? 1 : 0
                
                Behavior on opacity {
                    NumberAnimation {
                        duration: Settings.animationDurationMedium
                        easing.type: Easing.OutQuad
                    }
                }
                
                // Main OSD card
                Card {
                    id: osdCard
                    anchors.fill: parent
                    elevation: 3
                    showBorder: true
                    
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 4
                        
                        // Header row with icon and device name
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            
                            // Volume icon
                            Text {
                                readonly property int volPct: Math.round((Audio.muted ? 0 : Audio.volume) * 100)
                                text: Audio.muted ? "\ue04f" : volPct > 50 ? "\ue050" : volPct > 30 ? "\ue04d" : "\ue04e"
                                color: Audio.muted ? Theme.stateMuted : Theme.accent
                                font.family: Settings.fontFamilyIcons
                                font.pixelSize: Settings.fontSizeIcon
                                verticalAlignment: Text.AlignVCenter
                                
                                Behavior on color {
                                    ColorAnimation { duration: Settings.animationDurationShort }
                                }
                            }
                            
                            // Device name
                            Text {
                                Layout.fillWidth: true
                                text: Pipewire.defaultAudioSink?.description || "Audio Device"
                                color: Theme.textPrimary
                                font.pixelSize: Settings.fontSizeLarge
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }
                            
                            // Volume percentage
                            Text {
                                text: Audio.muted ? "Muted" : Math.round(Audio.volume * 100) + "%"
                                color: Audio.muted ? Theme.stateMuted : Theme.textPrimary
                                font.pixelSize: Settings.fontSizeLarge
                                font.weight: Font.Bold
                                
                                Behavior on color {
                                    ColorAnimation { duration: Settings.animationDurationShort }
                                }
                            }
                        }
                        
                        // Progress bar
                        ProgressBar {
                            Layout.fillWidth: true
                            value: Audio.muted ? 0 : Audio.volume
                            fillColor: Audio.muted ? Theme.stateMuted : Theme.accent
                        }
                    }
                }
            }
        }
    }
}
