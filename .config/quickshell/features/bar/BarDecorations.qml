pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.core
import qs.config

PanelWindow {
    id: root
    
    property bool is_overview: Niri.is_overview
    
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    
    anchors {
        left: true
        right: true
        top: true
    }
    
    Item {
        id: barRounding
        visible: !root.is_overview
        height: Settings.barHeight
        
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        
        RoundCorner {
            anchors.top: parent.bottom
            anchors.left: parent.left
            size: 16
            corner: cornerEnum.topLeft
            color: Theme.surfaceBase
            opacity: 1
        }
        
        RoundCorner {
            anchors.top: parent.bottom
            anchors.right: parent.right
            size: 16
            corner: cornerEnum.topRight
            color: Theme.surfaceBase
            opacity: 1
        }
    }
    
    mask: Region {
        x: 0
        y: Settings.barHeight
        height: Settings.barHeight
        intersection: Intersection.Intersect
    }
} 