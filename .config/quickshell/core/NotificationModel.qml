pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models

QtObject {
    id: root

    property ListModel model: ListModel {}

    function add(data) {
        model.append({
            "summary": data.summary || "",
            "body": data.body || "",
            "appName": data.appName || "",
            "appIcon": data.appIcon || "",
            "image": data.image || "",
            "id": data.id || 0,
            "timeout": data.timeout || 5000,
            "timestamp": Date.now()
        })
    }

    function remove(index) {
        model.remove(index)
    }

    function clear() {
        model.clear()
    }

    function count() {
        return model.count
    }
}
