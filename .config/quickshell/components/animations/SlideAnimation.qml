import QtQuick
import qs.config

/**
 * SlideAnimation - Reusable slide animation
 * Provides slide-in/out animations from different directions
 */
Item {
    id: root
    
    enum Direction {
        FromRight,
        FromLeft,
        FromTop,
        FromBottom
    }
    
    // Properties
    property Item target
    property int direction: SlideAnimation.Direction.FromRight
    property int distance: Settings.flickSlideDistance
    property int duration: Settings.animationDurationMedium
    property bool running: false
    
    // Transform for the target
    property Translate slideTransform: Translate {
        x: {
            if (!root.running) {
                switch(root.direction) {
                    case SlideAnimation.Direction.FromRight: return root.distance
                    case SlideAnimation.Direction.FromLeft: return -root.distance
                    default: return 0
                }
            }
            return 0
        }
        
        y: {
            if (!root.running) {
                switch(root.direction) {
                    case SlideAnimation.Direction.FromBottom: return root.distance
                    case SlideAnimation.Direction.FromTop: return -root.distance
                    default: return 0
                }
            }
            return 0
        }
        
        Behavior on x {
            NumberAnimation {
                duration: root.duration
                easing.type: Settings.easingStandard
            }
        }
        
        Behavior on y {
            NumberAnimation {
                duration: root.duration
                easing.type: Settings.easingStandard
            }
        }
    }
    
    Component.onCompleted: {
        if (target) {
            target.transform = slideTransform
        }
    }
}
