pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models

QtObject {
    id: root

    property ListModel pockets: ListModel {
        dynamicRoles: true
    }

    // Screen name → notification wrapper Item map
    property var notifWrappers: ({})
    // Screen name → LauncherPanel map
    property var launcherPanels: ({})

    function _getEntry(pocketId) {
        for (let i = 0; i < pockets.count; i++) {
            if (pockets.get(i).pocketId === pocketId)
                return { index: i, entry: pockets.get(i) }
        }
        return null
    }

    function _setAll(i, id, screen, x, y, w, h, radius, visible) {
        pockets.set(i, {
            pocketId: id,
            pocketScreen: screen,
            pocketX: x, pocketY: y,
            pocketW: w, pocketH: h,
            pocketRadius: radius,
            pocketVisible: visible
        })
    }

    function register(pocketId, screen, x, y, w, h, radius) {
        const existing = _getEntry(pocketId)
        if (existing)
            _setAll(existing.index, pocketId, screen, x, y, w, h, radius, true)
        else
            pockets.append({
                pocketId: pocketId,
                pocketScreen: screen,
                pocketX: x, pocketY: y,
                pocketW: w, pocketH: h,
                pocketRadius: radius,
                pocketVisible: true
            })
    }

    function unregister(pocketId) {
        const existing = _getEntry(pocketId)
        if (existing)
            _setAll(existing.index,
                existing.entry.pocketId,
                existing.entry.pocketScreen,
                existing.entry.pocketX,
                existing.entry.pocketY,
                0, 0,
                existing.entry.pocketRadius,
                false)
    }

    function updateGeometry(pocketId, x, y, w, h) {
        const existing = _getEntry(pocketId)
        if (existing)
            _setAll(existing.index,
                existing.entry.pocketId,
                existing.entry.pocketScreen,
                x, y, w, h,
                existing.entry.pocketRadius,
                existing.entry.pocketVisible)
    }
}
