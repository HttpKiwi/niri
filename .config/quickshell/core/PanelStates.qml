pragma Singleton

import QtQuick

QtObject {
    id: root

    property var _states: ({})

    function register(monitorName) {
        if (!_states[monitorName]) {
            _states[monitorName] = Qt.createQmlObject(
                "import QtQuick; QtObject { property bool launcher: false; property bool clipboard: false }",
                root
            );
        }
        return _states[monitorName]
    }

    function forName(monitorName) {
        return _states[monitorName] || null
    }
}
