pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

QtObject {
    id: root

    // Store references to created screen decorations
    property var screenDecorations: ({})
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
        createDecorationsForScreens()
        
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
            console.warn("Error updating known screens:", e)
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
                console.log("Screen configuration changed, recreating decorations...")
                console.log("Old screens:", lastKnownScreens.map(s => s.name))
                console.log("New screens:", currentScreens.map(s => s.name))
                
                updateLastKnownScreens()
                recreateAllDecorations()
            }
        } catch (e) {
            console.warn("Error checking screen changes:", e)
        }
    }

    function handleScreenChanges() {
        console.log("Screen configuration changed via signal")
        // Small delay to let the system settle
        Qt.callLater(() => {
            updateLastKnownScreens()
            recreateAllDecorations()
        })
    }

    function recreateAllDecorations() {
        try {
            // Destroy all existing decorations first
            for (const screenName in screenDecorations) {
                if (screenDecorations[screenName]) {
                    try {
                        screenDecorations[screenName].destroy()
                    } catch (e) {
                        console.warn("Error destroying decoration for screen", screenName, ":", e)
                    }
                }
            }
            screenDecorations = {}
            
            // Wait a moment for cleanup, then recreate
            Qt.callLater(createDecorationsForScreens)
        } catch (e) {
            console.error("Error in recreateAllDecorations:", e)
        }
    }

    function createDecorationsForScreens() {
        try {
            console.log("Creating decorations for screens:", Quickshell.screens.map(s => s.name))
            
            // Validate that we have screens
            if (Quickshell.screens.length === 0) {
                console.warn("No screens found from Quickshell")
                return
            }
            
            // Clean up existing decorations that are no longer needed
            const currentScreenNames = Quickshell.screens.map(s => s.name)
            for (const screenName in screenDecorations) {
                if (!currentScreenNames.includes(screenName)) {
                    console.log("Removing decoration for disconnected screen:", screenName)
                    if (screenDecorations[screenName]) {
                        try {
                            screenDecorations[screenName].destroy()
                        } catch (e) {
                            console.warn("Error destroying decoration:", e)
                        }
                        delete screenDecorations[screenName]
                    }
                }
            }

            // Create decorations for new screens
            for (const screen of Quickshell.screens) {
                if (!screenDecorations[screen.name]) {
                    createDecorationForScreen(screen)
                }
            }
        } catch (e) {
            console.error("Error in createDecorationsForScreens:", e)
        }
    }

    function createDecorationForScreen(screen) {
        try {
            const decorationComponent = Qt.createComponent("RoundedScreen.qml")
            
            if (decorationComponent.status === Component.Ready) {
                const decoration = decorationComponent.createObject(null, {
                    "targetScreen": screen
                })
                
                if (decoration) {
                    // Add error handling for the decoration
                    decoration.Component.onDestruction.connect(() => {
                        console.log("Decoration destroyed for screen:", screen.name)
                        if (screenDecorations[screen.name] === decoration) {
                            delete screenDecorations[screen.name]
                        }
                    })
                    
                    screenDecorations[screen.name] = decoration
                    console.log(`Created decoration for screen: ${screen.name} (${screen.width}x${screen.height})`)
                } else {
                    console.error(`Failed to create decoration for screen: ${screen.name}`)
                }
            } else if (decorationComponent.status === Component.Error) {
                console.error("Error creating decoration component:", decorationComponent.errorString())
            } else {
                // Component not ready yet, try again later
                Qt.callLater(() => createDecorationForScreen(screen))
            }
        } catch (e) {
            console.error("Exception in createDecorationForScreen:", e)
        }
    }
}
