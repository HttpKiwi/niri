import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Services

Scope {
    id: root

    property bool shouldShowOsd: false

    Connections {
        function onVolumeChanged() {
            root.shouldShowOsd = true;
            hideTimer.restart();
        }

        target: Audio
    }

    Timer {
        id: hideTimer

        interval: 1000
        onTriggered: root.shouldShowOsd = false
    }

    // The OSD window will be created and destroyed based on shouldShowOsd.
    // PanelWindow.visible could be set instead of using a loader, but using
    // a loader will reduce the memory overhead when the window isn't open.
    LazyLoader {
        active: root.shouldShowOsd

        PanelWindow {
            // Since the panel's screen is unset, it will be picked by the compositor
            // when the window is created. Most compositors pick the current active monitor.

            exclusiveZone: 0
            implicitWidth: 50
            implicitHeight: 140
            color: "transparent"

            anchors {
                right: true
            }

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: "#80000000"

                ColumnLayout {
                    anchors {
                        fill: parent
                        topMargin: 10
                        bottomMargin: 15
                    }

                    Rectangle {
                        // Stretches to fill all left-over space
                        Layout.fillHeight: true
                        implicitWidth: 10
                        radius: 20
                        color: "#50ffffff"

                        Rectangle {
                            implicitHeight: parent.height * (Audio.volume ?? 0)
                            radius: parent.radius

                            anchors {
                                bottom: parent.bottom
                                left: parent.left
                                right: parent.right
                            }

                        }

                    }

                }

            }

            // An empty click mask prevents the window from blocking mouse events.
            mask: Region {
            }

        }

    }

}
