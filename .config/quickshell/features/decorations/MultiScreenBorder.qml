pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

/**
 * MultiScreenBorder - Creates borders for all screens
 * Automatically manages borders as screens are added/removed
 */
QtObject {
    id: root
    
    property var screenBorders: ({})
    
    property Timer monitorCheckTimer: Timer {
        id: monitorCheckTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: checkScreenChanges()
    }
    
    property var lastKnownScreens: []
    
    Component.onCompleted: {
        updateLastKnownScreens()
        createBordersForScreens()
        Quickshell.screensChanged.connect(handleScreenChanges)
    }
    
    function updateLastKnownScreens() {
        try {
            lastKnownScreens = Quickshell.screens.map(s => ({
                name: s.name,
                width: s.width,
                height: s.height
            }))
        } catch (e) {
            console.warn("Error updating known screens for borders:", e)
            lastKnownScreens = []
        }
    }
    
    function checkScreenChanges() {
        try {
            const currentScreens = Quickshell.screens.map(s => ({
                name: s.name,
                width: s.width,
                height: s.height
            }))
            
            const screensChanged = JSON.stringify(currentScreens) !== JSON.stringify(lastKnownScreens)
            
            if (screensChanged) {
                console.log("Screen configuration changed, recreating borders...")
                console.log("Old screens:", lastKnownScreens.map(s => s.name))
                console.log("New screens:", currentScreens.map(s => s.name))
                
                updateLastKnownScreens()
                recreateAllBorders()
            }
        } catch (e) {
            console.warn("Error checking screen changes for borders:", e)
        }
    }
    
    function handleScreenChanges() {
        console.log("Screen configuration changed via signal for borders")
        Qt.callLater(() => {
            updateLastKnownScreens()
            recreateAllBorders()
        })
    }
    
    function recreateAllBorders() {
        try {
            for (const screenName in screenBorders) {
                if (screenBorders[screenName]) {
                    try {
                        screenBorders[screenName].destroy()
                    } catch (e) {
                        console.warn("Error destroying border for screen", screenName, ":", e)
                    }
                }
            }
            screenBorders = {}
            
            Qt.callLater(createBordersForScreens)
        } catch (e) {
            console.error("Error in recreateAllBorders:", e)
        }
    }
    
    function createBordersForScreens() {
        try {
            console.log("Creating borders for screens:", Quickshell.screens.map(s => s.name))
            
            if (Quickshell.screens.length === 0) {
                console.warn("No screens found from Quickshell for borders")
                return
            }
            
            const currentScreenNames = Quickshell.screens.map(s => s.name)
            for (const screenName in screenBorders) {
                if (!currentScreenNames.includes(screenName)) {
                    console.log("Removing border for disconnected screen:", screenName)
                    if (screenBorders[screenName]) {
                        try {
                            screenBorders[screenName].destroy()
                        } catch (e) {
                            console.warn("Error destroying border:", e)
                        }
                        delete screenBorders[screenName]
                    }
                }
            }
            
            for (const screen of Quickshell.screens) {
                if (!screenBorders[screen.name]) {
                    createBorderForScreen(screen)
                }
            }
        } catch (e) {
            console.error("Error in createBordersForScreens:", e)
        }
    }
    
    function createBorderForScreen(screen) {
        try {
            const borderComponent = Qt.createComponent("ScreenBorder.qml")
            
            if (borderComponent.status === Component.Ready) {
                const border = borderComponent.createObject(null, {
                    "screen": screen
                })
                
                if (border) {
                    border.Component.onDestruction.connect(() => {
                        console.log("Border destroyed for screen:", screen.name)
                        if (screenBorders[screen.name] === border) {
                            delete screenBorders[screen.name]
                        }
                    })
                    
                    screenBorders[screen.name] = border
                    console.log(`Created border for screen: ${screen.name} (${screen.width}x${screen.height})`)
                } else {
                    console.error(`Failed to create border for screen: ${screen.name}`)
                }
            } else if (borderComponent.status === Component.Error) {
                console.error("Error creating border component:", borderComponent.errorString())
            } else {
                Qt.callLater(() => createBorderForScreen(screen))
            }
        } catch (e) {
            console.error("Exception in createBorderForScreen:", e)
        }
    }
}
