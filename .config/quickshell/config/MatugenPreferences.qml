pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * MatugenPreferences - Stores and persists matugen color generation preferences
 * - Scheme type (9 Material You schemes)
 * - Color mode (dark/light)
 * - Contrast level (-1 to 1)
 */
QtObject {
    id: root

    // Available matugen scheme types
    readonly property var schemeTypes: [
        "scheme-tonal-spot",
        "scheme-content",
        "scheme-expressive",
        "scheme-fidelity",
        "scheme-fruit-salad",
        "scheme-monochrome",
        "scheme-neutral",
        "scheme-rainbow",
        "scheme-vibrant"
    ]

    // User-friendly names for schemes
    readonly property var schemeNames: {
        "scheme-tonal-spot": "Tonal Spot",
        "scheme-content": "Content",
        "scheme-expressive": "Expressive",
        "scheme-fidelity": "Fidelity",
        "scheme-fruit-salad": "Fruit Salad",
        "scheme-monochrome": "Monochrome",
        "scheme-neutral": "Neutral",
        "scheme-rainbow": "Rainbow",
        "scheme-vibrant": "Vibrant"
    }

    // Current preferences
    property string schemeType: "scheme-tonal-spot"
    property string colorMode: "dark"  // "dark" or "light"
    property real contrastLevel: 0.0   // -1.0 to 1.0

    // Preference file path
    readonly property string prefsFile: `${Quickshell.env("HOME")}/.config/quickshell/common/matugen-prefs.json`

    // Get user-friendly name for current scheme
    readonly property string schemeName: schemeNames[schemeType] || schemeType

    Component.onCompleted: {
        console.log("MatugenPreferences: Component initialized with defaults")
    }

    // FileView to load preferences from JSON
    property var prefsFileView: FileView {
        path: prefsFile

        onAdapterUpdated: {
            try {
                schemeType = adapter.schemeType || "scheme-tonal-spot"
                colorMode = adapter.colorMode || "dark"
                contrastLevel = adapter.contrastLevel || 0.0
                console.log(`MatugenPreferences: Loaded - scheme=${schemeType}, mode=${colorMode}, contrast=${contrastLevel}`)
            } catch (e) {
                console.log("MatugenPreferences: Failed to load preferences, using defaults")
            }
        }

        JsonAdapter {
            id: adapter
            property string schemeType
            property string colorMode
            property real contrastLevel
        }
    }

    // Save preferences to JSON file
    function savePreferences() {
        const prefs = {
            schemeType: schemeType,
            colorMode: colorMode,
            contrastLevel: contrastLevel
        }

        const json = JSON.stringify(prefs, null, 2)

        try {
            // Use Process to write file since Quickshell.writeFile doesn't exist
            preferenceSaver.command = ["sh", "-c", `echo '${json}' > '${prefsFile}'`]
            preferenceSaver.running = true
            console.log(`MatugenPreferences: Saved - scheme=${schemeType}, mode=${colorMode}, contrast=${contrastLevel}`)
        } catch (e) {
            console.error("MatugenPreferences: Failed to save preferences:", e)
        }
    }

    // Cycle to next scheme type
    function nextScheme() {
        const currentIndex = schemeTypes.indexOf(schemeType)
        const nextIndex = (currentIndex + 1) % schemeTypes.length
        schemeType = schemeTypes[nextIndex]
        savePreferences()
    }

    // Toggle between dark and light mode
    function toggleMode() {
        colorMode = (colorMode === "dark") ? "light" : "dark"
        savePreferences()
    }

    // Set contrast level (clamped to -1.0 to 1.0)
    function setContrast(value) {
        contrastLevel = Math.max(-1.0, Math.min(1.0, value))
        savePreferences()
    }

    // Process for saving preferences
    property var preferenceSaver: Process {
        running: false
    }
}
