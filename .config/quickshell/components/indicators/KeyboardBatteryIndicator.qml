import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import qs.config

/**
 * KeyboardBatteryIndicator - Left/right ZMK split battery from dongle HID.
 * Calm by default (icon only); blinks + shows the low side(s) when ≤ threshold.
 * Hover reveals full L/R levels.
 */
WrapperMouseArea {
    id: root

    property int leftLevel: -1
    property int rightLevel: -1
    property bool available: false
    hoverEnabled: true

    readonly property string reader: "/home/httpkiwi/Projects/Kiwiboard/zmk-split-battery-tray/host/zmk-split-battery.py"
    readonly property int lowThreshold: Settings.keyboardBatteryLowThreshold

    readonly property bool leftLow: available && leftLevel >= 0 && leftLevel <= lowThreshold
    readonly property bool rightLow: available && rightLevel >= 0 && rightLevel <= lowThreshold
    readonly property bool isLow: leftLow || rightLow

    readonly property string displayText: {
        if (root.containsMouse && root.available) {
            const l = root.leftLevel < 0 ? "—" : (root.leftLevel + "%");
            const r = root.rightLevel < 0 ? "—" : (root.rightLevel + "%");
            return "L " + l + "  R " + r;
        }
        if (!root.isLow)
            return "";
        // Only call out the side(s) that need charging
        let parts = [];
        if (root.leftLow)
            parts.push("L " + root.leftLevel + "%");
        if (root.rightLow)
            parts.push("R " + root.rightLevel + "%");
        return parts.join("  ");
    }

    Timer {
        // Must be > CLI --timeout so polls don't overlap
        interval: 6000
        running: true
        repeat: true
        onTriggered: checkBattery()
    }

    Component.onCompleted: checkBattery()

    function checkBattery() {
        if (process.running)
            return;
        process.running = true;
    }

    Process {
        id: process
        // HID reports are sporadic — a few short attempts beats one long wait.
        // --swap: ZMK slot 0/1 is pairing order, not physical left/right.
        command: {
            const cmd = [
                "python3", root.reader, "--json",
                "--timeout", "1.0", "--retries", "4"
            ];
            if (Settings.keyboardBatterySwapLR)
                cmd.push("--swap");
            return cmd;
        }
        running: false

        stdout: SplitParser {
            id: outputParser
            property string collectedOutput: ""
            onRead: data => {
                collectedOutput += data;
            }
        }

        stderr: SplitParser {
            onRead: data => {}
        }

        onRunningChanged: {
            if (running)
                return;

            const output = outputParser.collectedOutput.trim();
            outputParser.collectedOutput = "";

            if (!output)
                return;

            try {
                const data = JSON.parse(output);
                const status = (data.status || "").toString();

                if (status === "AVAILABLE") {
                    const left = data.left;
                    const right = data.right;
                    root.leftLevel = (left === null || left === undefined) ? -1 : parseInt(left, 10);
                    root.rightLevel = (right === null || right === undefined) ? -1 : parseInt(right, 10);
                    if (isNaN(root.leftLevel))
                        root.leftLevel = -1;
                    if (isNaN(root.rightLevel))
                        root.rightLevel = -1;
                    root.available = true;
                } else if (status === "MISSING") {
                    root.available = false;
                    root.leftLevel = -1;
                    root.rightLevel = -1;
                }
                // WAITING: keep last good reading
            } catch (e) {
                console.warn("KeyboardBattery: bad JSON", output, e);
            }
        }
    }

    Row {
        spacing: 4
        anchors.centerIn: parent

        Text {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -1
            // Material Symbols Rounded: keyboard
            text: "\ue312"
            color: root.isLow ? Theme.error : Theme.textPrimary
            font.family: Settings.fontFamilyIcons
            font.pixelSize: 14
            opacity: 1

            SequentialAnimation on opacity {
                running: root.isLow
                loops: Animation.Infinite
                NumberAnimation { from: 1; to: 0.25; duration: 650; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 0.25; to: 1; duration: 650; easing.type: Easing.InOutQuad }
                onStopped: icon.opacity = 1
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.displayText.length > 0
            color: root.isLow && !root.containsMouse ? Theme.error : (root.available ? Theme.textPrimary : Theme.textSecondary)
            font.family: Settings.fontFamilyDefault
            font.pixelSize: Settings.fontSizeBar
            font.features: { "tnum": 1 }
            text: root.displayText
        }
    }
}
