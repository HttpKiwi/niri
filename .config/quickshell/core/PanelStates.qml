pragma Singleton

import QtQuick

QtObject {
    id: root

    property var _states: ({})

    function register(monitorName) {
        if (!_states[monitorName]) {
            _states[monitorName] = panelStateComponent.createObject(root);
        }
        return _states[monitorName];
    }

    function forName(monitorName) {
        return _states[monitorName] || null;
    }

    property Component panelStateComponent: Component {
        PanelState {}
    }
}
