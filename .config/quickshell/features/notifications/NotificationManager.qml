pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.core
import qs.config

/**
 * NotificationManager - Manages multiple notification popups
 * Handles stacking, positioning, and lifecycle of notification windows
 */
QtObject {
    id: manager

    property int topMargin: 0
    property int baseNotificationHeight: Settings.notificationSpacing
    property int maxNotifications: Settings.notificationMaxStack
    property var popupWindows: []
    property var destroyingWindows: new Set()
    
    property Component popupComponent: Component {
        NotificationPopup {
            onEntered: manager._onPopupEntered(this)
            onExitFinished: manager._onPopupExitFinished(this)
        }
    }

    // Listen to notification service
    property Connections notificationConnections: Connections {
        target: NotificationService
        
        function onNotificationReceived(notification) {
            manager._addNotification(notification)
        }
    }

    // Cleanup timer - removes zombie windows
    property Timer sweeper: Timer {
        interval: 500
        running: false
        repeat: true
        onTriggered: {
            const toRemove = []
            for (const p of popupWindows) {
                if (!p) {
                    toRemove.push(p)
                    continue
                }
                const isZombie = p.status === Component.Null || 
                                (!p.visible && !p.exiting) || 
                                (!p.notificationData && !p._isDestroying) ||
                                (!p.hasValidData && !p._isDestroying)
                if (isZombie) {
                    toRemove.push(p)
                    if (p.forceExit) {
                        p.forceExit()
                    } else if (p.destroy) {
                        try {
                            p.destroy()
                        } catch (e) {
                            console.warn("Error destroying popup:", e)
                        }
                    }
                }
            }
            
            if (toRemove.length) {
                popupWindows = popupWindows.filter(p => toRemove.indexOf(p) === -1)
                _repositionSurvivors()
            }
            
            if (popupWindows.length === 0) {
                sweeper.stop()
            }
        }
    }

    // Add a new notification
    function _addNotification(notification) {
        if (!notification || !notification.summary) {
            return
        }
        
        // Create notification data object
        const notificationData = {
            summary: notification.summary || "",
            body: notification.body || "",
            appName: notification.appName || "",
            appIcon: notification.appIcon || "",
            image: notification.image || "",
            id: notification.id || 0,
            timeout: notification.expireTimeout || Settings.notificationTimeout
        }
        
        // Save to notification history (before dismissal)
        try {
            NotificationStore.addNotification(notificationData)
        } catch (e) {
            console.warn("Error saving notification to history:", e)
        }
        
        // Make room if at capacity
        const activeWindows = _active()
        if (activeWindows.length >= maxNotifications) {
            _makeRoomForNew()
        }
        
        // Shift existing notifications down
        for (const p of popupWindows) {
            if (_isValidWindow(p) && !p.exiting) {
                p.screenY = p.screenY + baseNotificationHeight
            }
        }
        
        // Create new popup window
        const win = popupComponent.createObject(null, {
            "notificationData": notificationData,
            "screenY": topMargin
        })
        
        if (!win) {
            console.warn("Failed to create notification popup")
            return
        }
        
        if (!win.hasValidData) {
            win.destroy()
            return
        }
        
        popupWindows.push(win)
        
        if (!sweeper.running) {
            sweeper.start()
        }
    }

    // Get active (visible, non-exiting) windows
    function _active() {
        return popupWindows.filter(p => _isValidWindow(p) && !p.exiting)
    }

    // Check if window is valid
    function _isValidWindow(p) {
        return p && p.status !== Component.Null && !p._isDestroying && p.hasValidData
    }

    // Make room for new notification by removing oldest
    function _makeRoomForNew() {
        const activeWindows = _active()
        if (activeWindows.length === 0) return
        
        // Remove the bottom-most (oldest) notification
        const sortedWindows = activeWindows.slice().sort((a, b) => b.screenY - a.screenY)
        const toRemove = sortedWindows[0]
        
        if (toRemove && !toRemove.exiting) {
            toRemove.startExit()
        }
    }

    // Reposition surviving windows
    function _repositionSurvivors() {
        const survivors = _active().sort((a, b) => a.screenY - b.screenY)
        for (let k = 0; k < survivors.length; ++k) {
            survivors[k].screenY = topMargin + k * baseNotificationHeight
        }
    }

    // Popup entered (animation complete)
    function _onPopupEntered(p) {
        // Can add logic here if needed
    }

    // Popup exit finished
    function _onPopupExitFinished(p) {
        if (!p) return
        
        const windowId = p.toString()
        if (destroyingWindows.has(windowId)) {
            return
        }
        destroyingWindows.add(windowId)
        
        const i = popupWindows.indexOf(p)
        if (i !== -1) {
            popupWindows.splice(i, 1)
            popupWindows = popupWindows.slice()
        }
        
        Qt.callLater(() => {
            if (p && p.destroy) {
                try {
                    p.destroy()
                } catch (e) {
                    console.warn("Error destroying popup:", e)
                }
            }
            Qt.callLater(() => destroyingWindows.delete(windowId))
        })
        
        _repositionSurvivors()
    }

    // Cleanup all windows
    function cleanupAllWindows() {
        sweeper.stop()
        for (const p of popupWindows.slice()) {
            if (p) {
                try {
                    if (p.forceExit) {
                        p.forceExit()
                    } else if (p.destroy) {
                        p.destroy()
                    }
                } catch (e) {
                    console.warn("Error cleaning up popup:", e)
                }
            }
        }
        popupWindows = []
        destroyingWindows.clear()
    }

    onPopupWindowsChanged: {
        if (popupWindows.length > 0 && !sweeper.running) {
            sweeper.start()
        } else if (popupWindows.length === 0 && sweeper.running) {
            sweeper.stop()
        }
    }
}
