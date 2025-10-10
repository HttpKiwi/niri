pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.core

/**
 * MultiMonitorBar - Creates and manages bars for multiple monitors
 * Automatically creates/destroys bars as monitors are added/removed
 */
QtObject {
    id: root
    
    property var monitorBars: ({})
    
    property Timer monitorCheckTimer: Timer {
        id: monitorCheckTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: checkMonitorChanges()
    }
    
    property var lastKnownScreens: []
    property var lastKnownMonitors: []
    
    Component.onCompleted: {
        updateLastKnownStates()
        createBarsForMonitors()
        
        Niri.workspaces_by_monitorChanged.connect(createBarsForMonitors)
        Quickshell.screensChanged.connect(handleScreenChanges)
    }
    
    function createBarsForMonitors() {
        try {
            const monitors = Niri.getMonitorNames()
            
            if (monitors.length === 0 || Quickshell.screens.length === 0) {
                return
            }
            
            // Clean up bars for removed monitors
            for (const monitor in monitorBars) {
                if (!monitors.includes(monitor)) {
                    if (monitorBars[monitor]) {
                        try {
                            monitorBars[monitor].destroy()
                        } catch (e) {}
                        delete monitorBars[monitor]
                    }
                }
            }
            
            // Create bars for new monitors
            for (const monitor of monitors) {
                if (!monitorBars[monitor]) {
                    createBarForMonitor(monitor)
                }
            }
        } catch (e) {}
    }
    
    function createBarForMonitor(monitorName) {
        try {
            const barComponent = Qt.createComponent("Bar.qml")
            
            if (barComponent.status === Component.Ready) {
                let targetScreen = null
                
                // Find screen by name
                for (let i = 0; i < Quickshell.screens.length; i++) {
                    const screen = Quickshell.screens[i]
                    if (screen.name === monitorName) {
                        targetScreen = screen
                        break
                    }
                }
                
                // Fallback: assign screens in order
                if (!targetScreen && Quickshell.screens.length > 0) {
                    const monitorList = Niri.getMonitorNames()
                    const monitorIndex = monitorList.indexOf(monitorName)
                    if (monitorIndex >= 0 && monitorIndex < Quickshell.screens.length) {
                        targetScreen = Quickshell.screens[monitorIndex]
                    } else {
                        targetScreen = Quickshell.screens[0]
                    }
                }
                
                if (targetScreen) {
                    const bar = barComponent.createObject(null, {
                        "targetMonitor": monitorName,
                        "screen": targetScreen
                    })
                    
                    if (bar) {
                        bar.Component.onDestruction.connect(() => {
                            if (monitorBars[monitorName] === bar) {
                                delete monitorBars[monitorName]
                            }
                        })
                        
                        monitorBars[monitorName] = bar
                    } else {
                        console.error(`Failed to create bar for monitor: ${monitorName}`)
                    }
                } else {
                    console.error(`No screen found for monitor: ${monitorName}`)
                }
            } else if (barComponent.status === Component.Error) {
                console.error("Error creating bar component:", barComponent.errorString())
            } else {
                Qt.callLater(() => createBarForMonitor(monitorName))
            }
        } catch (e) {
            console.error("Exception in createBarForMonitor:", e)
        }
    }
    
    function updateLastKnownStates() {
        lastKnownScreens = Quickshell.screens.map(s => s.name)
        lastKnownMonitors = Niri.getMonitorNames()
    }
    
    function checkMonitorChanges() {
        const currentScreens = Quickshell.screens.map(s => s.name)
        const currentMonitors = Niri.getMonitorNames()
        
        const screensChanged = JSON.stringify(currentScreens.sort()) !== JSON.stringify(lastKnownScreens.sort())
        const monitorsChanged = JSON.stringify(currentMonitors.sort()) !== JSON.stringify(lastKnownMonitors.sort())
        
        if (screensChanged || monitorsChanged) {
            console.log("Monitor configuration changed, recreating bars...")
            updateLastKnownStates()
            recreateAllBars()
        }
    }
    
    function handleScreenChanges() {
        console.log("Screen configuration changed via signal")
        Qt.callLater(() => {
            updateLastKnownStates()
            recreateAllBars()
        })
    }
    
    function recreateAllBars() {
        for (const monitor in monitorBars) {
            if (monitorBars[monitor]) {
                try {
                    monitorBars[monitor].destroy()
                } catch (e) {
                    console.warn("Error destroying bar for monitor", monitor, ":", e)
                }
            }
        }
        monitorBars = {}
        
        Qt.callLater(createBarsForMonitors)
    }
}
