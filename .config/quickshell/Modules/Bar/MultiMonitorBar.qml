pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import qs.Services
QtObject {
    id: root

    // Store references to created bars
    property var monitorBars: ({})
    property var monitorCheckTimer: Timer {
        id: monitorCheckTimer
        interval: 1000  // Check every second
        running: true
        repeat: true
        onTriggered: checkMonitorChanges()
    }

    property var lastKnownScreens: []
    property var lastKnownMonitors: []

    Component.onCompleted: {
        // Initial setup
        updateLastKnownStates();
        createBarsForMonitors();

        // Connect to workspace changes
        Niri.workspaces_by_monitorChanged.connect(createBarsForMonitors);

        // Monitor screen changes
        Quickshell.screensChanged.connect(handleScreenChanges);
    }

    function createBarsForMonitors() {
        try {
            // Get list of monitors from Niri service
            const monitors = Niri.getMonitorNames();

            // Validate that we have both monitors and screens
            if (monitors.length === 0) {
                return;
            }

            if (Quickshell.screens.length === 0) {
                return;
            }

            // Clean up existing bars that are no longer needed
            for (const monitor in monitorBars) {
                if (!monitors.includes(monitor)) {
                    if (monitorBars[monitor]) {
                        try {
                            monitorBars[monitor].destroy();
                        } catch (e) {}
                        delete monitorBars[monitor];
                    }
                }
            }

            // Create bars for new monitors
            for (const monitor of monitors) {
                if (!monitorBars[monitor]) {
                    createBarForMonitor(monitor);
                }
            }
        } catch (e) {}
    }

    function createBarForMonitor(monitorName) {
        try {
            const barComponent = Qt.createComponent("Bar.qml");

            if (barComponent.status === Component.Ready) {
                // Try to find the screen by name
                let targetScreen = null;
                for (let i = 0; i < Quickshell.screens.length; i++) {
                    const screen = Quickshell.screens[i];
                    if (screen.name === monitorName) {
                        targetScreen = screen;
                        break;
                    }
                }

                // If we can't find the exact screen, assign screens in order
                if (!targetScreen && Quickshell.screens.length > 0) {
                    const monitorList = Niri.getMonitorNames();
                    const monitorIndex = monitorList.indexOf(monitorName);
                    if (monitorIndex >= 0 && monitorIndex < Quickshell.screens.length) {
                        targetScreen = Quickshell.screens[monitorIndex];
                    } else {
                        targetScreen = Quickshell.screens[0]; // fallback to first screen
                    }
                }

                if (targetScreen) {
                    const bar = barComponent.createObject(null, {
                        "targetMonitor": monitorName,
                        "screen": targetScreen
                    });

                    if (bar) {
                        // Add error handling for the bar
                        bar.Component.onDestruction.connect(() => {
                            if (monitorBars[monitorName] === bar) {
                                delete monitorBars[monitorName];
                            }
                        });

                        monitorBars[monitorName] = bar;
                    } else {
                        console.error(`Failed to create bar for monitor: ${monitorName}`);
                    }
                } else {
                    console.error(`No screen found for monitor: ${monitorName}`);
                }
            } else if (barComponent.status === Component.Error) {
                console.error("Error creating bar component:", barComponent.errorString());
            } else {
                // Component not ready yet, try again later
                Qt.callLater(() => createBarForMonitor(monitorName));
            }
        } catch (e) {
            console.error("Exception in createBarForMonitor:", e);
        }
    }

    function updateLastKnownStates() {
        lastKnownScreens = Quickshell.screens.map(s => s.name);
        lastKnownMonitors = Niri.getMonitorNames();
    }

    function checkMonitorChanges() {
        const currentScreens = Quickshell.screens.map(s => s.name);
        const currentMonitors = Niri.getMonitorNames();

        // Check if screens or monitors have changed
        const screensChanged = JSON.stringify(currentScreens.sort()) !== JSON.stringify(lastKnownScreens.sort());
        const monitorsChanged = JSON.stringify(currentMonitors.sort()) !== JSON.stringify(lastKnownMonitors.sort());

        if (screensChanged || monitorsChanged) {
            console.log("Monitor configuration changed, recreating bars...");
            console.log("Old screens:", lastKnownScreens);
            console.log("New screens:", currentScreens);
            console.log("Old monitors:", lastKnownMonitors);
            console.log("New monitors:", currentMonitors);

            updateLastKnownStates();
            recreateAllBars();
        }
    }

    function handleScreenChanges() {
        console.log("Screen configuration changed via signal");
        // Small delay to let the system settle
        Qt.callLater(() => {
            updateLastKnownStates();
            recreateAllBars();
        });
    }

    function recreateAllBars() {
        // Destroy all existing bars first
        for (const monitor in monitorBars) {
            if (monitorBars[monitor]) {
                try {
                    monitorBars[monitor].destroy();
                } catch (e) {
                    console.warn("Error destroying bar for monitor", monitor, ":", e);
                }
            }
        }
        monitorBars = {};

        // Wait a moment for cleanup, then recreate
        Qt.callLater(createBarsForMonitors);
    }
}
