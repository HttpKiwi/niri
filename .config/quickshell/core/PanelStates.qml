pragma Singleton

import QtQuick

QtObject {
    id: root

    property var _states: ({})
    property bool anyPanelOpen: false

    function register(monitorName) {
        if (!_states[monitorName]) {
            _states[monitorName] = panelStateComponent.createObject(root);
            _states[monitorName].flagsChanged.connect(root.recomputeOpen);
        }
        return _states[monitorName];
    }

    function forName(monitorName) {
        return _states[monitorName] || null;
    }

    function recomputeOpen() {
        for (const name in _states) {
            const s = _states[name];
            if (!s)
                continue;
            if (s.launcher || s.wallpaper || s.controlCenter || s.osd || s.settings) {
                anyPanelOpen = true;
                return;
            }
        }
        anyPanelOpen = false;
    }

    property Component panelStateComponent: Component {
        PanelState {}
    }
}
