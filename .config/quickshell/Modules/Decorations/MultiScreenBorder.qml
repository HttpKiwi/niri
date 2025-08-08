pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

QtObject {
    id: root

    // Store references to created screen borders
    property var screenBorders: ({})
    property var monitorCheckTimer: Timer {
        id: monitorCheckTimer
        interval: 1000  // Check every second
        running: true
        repeat: true
        onTriggered: checkScreenChanges()
    }

    property var lastKnownScreens: []

    Component.onCompleted: {
        // Initial setup
        updateLastKnownScreens()
        createBordersForScreens()
        
        // Monitor screen changes
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
            
            // Check if screens have changed
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
        // Small delay to let the system settle
        Qt.callLater(() => {
            updateLastKnownScreens()
            recreateAllBorders()
        })
    }

    function recreateAllBorders() {
        try {
            // Destroy all existing borders first
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
            
            // Wait a moment for cleanup, then recreate
            Qt.callLater(createBordersForScreens)
        } catch (e) {
            console.error("Error in recreateAllBorders:", e)
        }
    }

    function createBordersForScreens() {
        try {
            console.log("Creating borders for screens:", Quickshell.screens.map(s => s.name))
            
            // Validate that we have screens
            if (Quickshell.screens.length === 0) {
                console.warn("No screens found from Quickshell for borders")
                return
            }
            
            // Clean up existing borders that are no longer needed
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

            // Create borders for new screens
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
                    // Add error handling for the border
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
                // Component not ready yet, try again later
                Qt.callLater(() => createBorderForScreen(screen))
            }
        } catch (e) {
            console.error("Exception in createBorderForScreen:", e)
        }
    }
}
