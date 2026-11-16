pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

/**
 * Audio - default sink and source over Pipewire. `changed` fires on real
 * volume/mute changes (not on startup) so the island can show them.
 */
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool micMuted: source?.audio?.muted ?? false
    readonly property string sinkName: sink?.description || sink?.nickname || sink?.name || ""

    signal changed()

    // Ignore the values Pipewire reports while binding at startup / device switches
    property bool _settled: false
    Timer { id: settle; interval: 1500; running: true; onTriggered: root._settled = true }
    onSinkChanged: { _settled = false; settle.restart(); }
    onVolumeChanged: if (_settled) changed()
    onMutedChanged: if (_settled) changed()
    onMicMutedChanged: if (_settled) changed()

    function _sinkReady() { return sink?.ready && sink?.audio; }
    function raiseVolume() { if (_sinkReady()) { sink.audio.muted = false; sink.audio.volume = Math.min(1, sink.audio.volume + 0.05); } }
    function lowerVolume() { if (_sinkReady()) { sink.audio.muted = false; sink.audio.volume = Math.max(0, sink.audio.volume - 0.05); } }
    function toggleMute() { if (_sinkReady()) sink.audio.muted = !sink.audio.muted; }
    function toggleMicMute() { if (source?.ready && source?.audio) source.audio.muted = !source.audio.muted; }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }
}
