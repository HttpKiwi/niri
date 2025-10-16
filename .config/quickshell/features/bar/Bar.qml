pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.core
import qs.config
import qs.components.base
import qs.components.indicators

/**
 * Bar - Main top bar component
 * Displays workspaces, window title, and system indicators
 */
PanelWindow {
    id: barWindow
    
    property string targetMonitor: ""
    
    anchors {
        top: true
        left: true
        right: true
    }
    
    color: "transparent"
    implicitHeight: 40
    exclusiveZone: Settings.barExclusiveZone
    
    Rectangle {
        id: barContent
        visible: !Niri.is_overview
        
        anchors {
            right: parent.right
            left: parent.left
            top: parent.top
            verticalCenter: parent.verticalCenter
        }
        
        color: Theme.surfaceBase
        height: Settings.barHeight
        
        // Center - Window title
        Text {
            id: title
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Settings.barContentMargin
            anchors.rightMargin: Settings.barContentMargin
            anchors.horizontalCenter: parent.horizontalCenter

            text: Niri.title
            color: Theme.textPrimary
            font.pixelSize: Settings.fontSizeLarge

            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }
        
        // Left - Workspaces
        Row {
            id: workspaces
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Settings.barContentMargin
            spacing: Settings.barWorkspaceSpacing
            
            Repeater {
                model: {
                    try {
                        if (barWindow.targetMonitor) {
                            const workspaces = Niri.getWorkspacesForMonitor(barWindow.targetMonitor)
                            return workspaces || []
                        } else {
                            return Niri.workspaces || []
                        }
                    } catch (e) {
                        console.warn("Error getting workspaces:", e)
                        return []
                    }
                }
                
                delegate: WorkspaceIndicator {
                    required property var modelData
                    workspace: modelData
                    isActive: {
                        if (barWindow.targetMonitor) {
                            return modelData.idx === Niri.focused_workspace_idx && 
                                   modelData.output === Niri.focused_output_name
                        }
                        return modelData.is_focused
                    }
                }
            }
        }
        
        // Right - System indicators
        RowLayout {
            id: systemIndicators
            spacing: Settings.barModuleSpacing
            anchors.right: parent.right
            anchors.rightMargin: Settings.barContentMargin
            anchors.verticalCenter: parent.verticalCenter
            
            // Volume pill
            Pill {
                VolumeIndicator {}
            }
            
            // Status pill
            Pill {
                ResourceIndicator {}
            }
            
            // Date pill
            Pill {
                DateIndicator {}
            }
            
            // Time pill
            Pill {
                TimeIndicator {}
            }
        }
    }
}
