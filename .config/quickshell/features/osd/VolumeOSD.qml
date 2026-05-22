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

    property bool shouldShowOsd: false
    property var targetScreen: (Quickshell.screens && Quickshell.screens.length > 0) ? Quickshell.screens[0] : null

    Component.onCompleted: {
        targetScreen = getFocusedScreen();
    }

    function getFocusedScreen() {
        const screens = Quickshell.screens || [];
        for (let i = 0; i < screens.length; i++) {
            if (screens[i].name === Niri.focused_output_name)
                return screens[i];
        }
        return screens[0] || null;
    }

    onShouldShowOsdChanged: {
        if (shouldShowOsd) {
            targetScreen = getFocusedScreen();
        }
    }

    function computeCenterX() {
        var screen = targetScreen;
        if (!screen) return 960;
        var w = screen.width;
        if (!w) return 960;
        return (w - Settings.osdWidth) / 2;
    }
    
    readonly property int _centerX: computeCenterX()

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
            screen: root.targetScreen

            // Position at bottom-center using margins
            anchors {
                bottom: true
            }
            
            margins {
                bottom: Settings.osdBottomMargin
                left: root._centerX
                right: root._centerX
            }
            
            // Mask to clip to rounded shape
            mask: Region {
                item: osdContainer
            }

            Component.onCompleted: registerPocket()

            function registerPocket() {
                const screen = root.targetScreen || Quickshell.screens[0];
                if (screen) {
                    const x = (screen.width - Settings.osdWidth) / 2;
                    const y = screen.height - Settings.osdHeight - Settings.osdBottomMargin;
                    PopupRegistry.register("osd", Niri.focused_output_name, x, y + slideTransform.y, Settings.osdWidth, Settings.osdHeight + 50, Settings.cardRadius);
                }
            }

            Connections {
                target: root
                function onShouldShowOsdChanged() {
                    if (root.shouldShowOsd)
                        osdWindow.registerPocket()
                    else
                        PopupRegistry.unregister("osd");
                }
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

                    onYChanged: {
                        const entry = PopupRegistry._getEntry("osd");
                        if (!entry || !entry.entry.pocketVisible) return;
                        const screen = root.targetScreen || Quickshell.screens[0];
                        if (screen) {
                            const baseX = (screen.width - Settings.osdWidth) / 2;
                            const baseY = screen.height - Settings.osdHeight - Settings.osdBottomMargin;
                            PopupRegistry.updateGeometry("osd", baseX, baseY + y, Settings.osdWidth, Settings.osdHeight + 50);
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
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.topMargin: 12
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    anchors.bottomMargin: 8
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
