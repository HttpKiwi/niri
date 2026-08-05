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
            "desktopEntry": data.desktopEntry || "",
            "actions": data.actions || [],
            "timeout": data.timeout || 5000,
            "timestamp": Date.now()
        })
    }

    function remove(index) {
        if (index >= 0 && index < model.count)
            model.remove(index)
    }

    function removeById(id) {
        const key = String(id)
        for (let i = 0; i < model.count; i++) {
            if (String(model.get(i).id) === key) {
                model.remove(i)
                return
            }
        }
    }

    function clear() {
        model.clear()
    }

    function count() {
        return model.count
    }
}
