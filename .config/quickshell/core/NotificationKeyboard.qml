pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import qs.core

/**
 * NotificationKeyboard - Shared keyboard state for popup notification stack
 */
QtObject {
    id: root

    property int popupFocusIndex: -1
    property bool popupKeyboardActive: false

    function popupCount() {
        return NotificationModel.count()
    }

    function clampPopupFocus() {
        const count = popupCount()
        if (count === 0) {
            popupFocusIndex = -1
            popupKeyboardActive = false
            return false
        }
        if (popupFocusIndex < 0 || popupFocusIndex >= count)
            popupFocusIndex = count - 1
        return true
    }

    function focusPopup() {
        if (!clampPopupFocus())
            return
        popupKeyboardActive = true
    }

    function dismissFocusedPopup() {
        const count = popupCount()
        if (count === 0)
            return

        if (!popupKeyboardActive)
            focusPopup()

        if (!clampPopupFocus())
            return

        const item = NotificationModel.model.get(popupFocusIndex)
        if (item)
            NotificationService.hidePopup(item.id, false)
    }

    function navigatePopup(delta) {
        if (!popupKeyboardActive)
            focusPopup()
        if (!clampPopupFocus())
            return
        popupFocusIndex = Math.max(0, Math.min(popupCount() - 1, popupFocusIndex + delta))
    }

    function activateFocusedPopup() {
        if (!popupKeyboardActive)
            focusPopup()
        if (!clampPopupFocus())
            return

        const item = NotificationModel.model.get(popupFocusIndex)
        if (item)
            NotificationService.activate(item)
    }

    function onPopupCountChanged() {
        clampPopupFocus()
        if (popupCount() === 0)
            popupKeyboardActive = false
    }
}
