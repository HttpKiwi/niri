pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire


Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real volume: sink?.audio?.volume ?? 0

    function setVolume(volume: real): void {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = volume;
        }
    }

    function toggleMute(): void {
        if (sink?.ready && sink?.audio) {
            console.log("Audio muted:", sink.audio.muted);
            sink.audio.muted = !sink.audio.muted;
        }
    }

    function lowerVolume(): void {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, sink.audio.volume - 0.05);
        }
    }

    function raiseVolume(): void {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.min(1, sink.audio.volume + 0.05);
        }
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }
}
