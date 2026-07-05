pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire


Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property var streams: Pipewire.audioStreams

    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real volume: sink?.audio?.volume ?? 0

    readonly property bool micMuted: source?.audio?.muted ?? false
    readonly property real micVolume: source?.audio?.volume ?? 0

    onSinkChanged: {
        volumeChanged()
        mutedChanged()
    }

    onSourceChanged: {
        micVolumeChanged()
        micMutedChanged()
    }

    function setVolume(vol: real): void {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(1, vol));
        }
    }

    function toggleMute(): void {
        if (sink?.ready && sink?.audio) {
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

    function getVolume(): int {
        return Math.round((sink?.audio?.volume ?? 0) * 100);
    }

    function setMicVolume(vol: real): void {
        if (source?.ready && source?.audio) {
            source.audio.muted = false;
            source.audio.volume = Math.max(0, Math.min(1, vol));
        }
    }

    function toggleMicMute(): void {
        if (source?.ready && source?.audio) {
            source.audio.muted = !source.audio.muted;
        }
    }

    function getMicVolume(): int {
        return Math.round((source?.audio?.volume ?? 0) * 100);
    }

    function setStreamVolume(stream, vol: real): void {
        if (stream?.audio) {
            stream.audio.muted = false;
            stream.audio.volume = Math.max(0, Math.min(1, vol));
        }
    }

    function getStreamVolume(stream): real {
        return stream?.audio?.volume ?? 0;
    }

    function setStreamMuted(stream, muted: bool): void {
        if (stream?.audio) {
            stream.audio.muted = muted;
        }
    }

    function getStreamMuted(stream): bool {
        return stream?.audio?.muted ?? false;
    }

    function getStreamName(stream): string {
        if (!stream) return "Unknown";
        if (stream.description) return stream.description;
        if (stream.name) return stream.name;
        return "Unknown";
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }
}
