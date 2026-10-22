import QtQuick
import qs.config

/**
 * CrossfadeImage - Wallpaper that fades (with a slight settle-in zoom) to each
 * new image once it has fully loaded.
 *
 * Two layers alternate: a request always loads into the hidden one, so the
 * image on screen is never reloaded (no flash). Each layer keeps its own
 * url/clip/size, so a later crop refinement of the same wallpaper just fades
 * the leaner decode over the old one and frees it.
 *
 * A request arriving mid-fade is queued (latest wins) until the fade ends:
 * restarting the fading layer would briefly re-expose the previous wallpaper.
 */
Item {
    id: root

    // { url, clip (rect or null), size (size or null) } — null clears
    property var request: null
    property int duration: 700
    property int fillMode: Image.PreserveAspectCrop

    property Image _front: null
    property Image _pending: null
    property string _key: ""
    property bool _queued: false

    onRequestChanged: _apply()

    function _apply() {
        if (fadeIn.running) {
            _queued = true;
            return;
        }
        _queued = false;
        const r = request && request.url ? request : null;
        const key = r ? JSON.stringify([r.url, r.clip, r.size]) : "";
        if (key === _key)
            return;
        _key = key;

        if (!r) {
            if (_front)
                fadeOut.start();
            return;
        }

        const next = _front === layerA ? layerB : layerA;
        fadeIn.stop();
        next.opacity = 0;
        next.scale = 1.04;
        next.z = 1;
        if (_front)
            _front.z = 0;
        _pending = next;
        next.req = r;
        if (next.status === Image.Ready)
            _reveal(next);
    }

    function _reveal(layer) {
        if (layer !== _pending)
            return;
        fadeIn.target = layer;
        fadeIn.start();
    }

    function _finish() {
        const old = _front;
        _front = _pending;
        _pending = null;
        // Release the previous decode once it's fully covered
        if (old && old !== _front)
            old.req = null;
        // Next turn: the animation may still report running inside onFinished
        if (_queued)
            Qt.callLater(_apply);
    }

    ParallelAnimation {
        id: fadeIn
        property Item target: null
        NumberAnimation {
            target: fadeIn.target
            property: "opacity"
            to: 1
            duration: root.duration
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: fadeIn.target
            property: "scale"
            to: 1
            duration: root.duration * 1.4
            easing.type: Easing.OutCubic
        }
        onFinished: root._finish()
    }

    NumberAnimation {
        id: fadeOut
        target: root._front
        property: "opacity"
        to: 0
        duration: root.duration
        onFinished: {
            if (root._front)
                root._front.req = null;
            root._front = null;
        }
    }

    component Layer: Image {
        property var req: null
        anchors.fill: parent
        source: req ? req.url : ""
        sourceClipRect: req && req.clip ? req.clip : Qt.rect(0, 0, 0, 0)
        sourceSize: req && req.size ? req.size : undefined
        fillMode: root.fillMode
        asynchronous: true
        cache: true
        smooth: true
        opacity: 0
        onStatusChanged: {
            if (status === Image.Ready)
                root._reveal(this);
        }
    }

    Layer {
        id: layerA
    }

    Layer {
        id: layerB
    }
}
