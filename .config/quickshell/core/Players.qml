pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

/**
 * Players - MPRIS media player service singleton
 * Wraps Quickshell's Mpris module for media control
 */
Singleton {
    id: root

    readonly property list<MprisPlayer> list: Mpris.players.values
    readonly property MprisPlayer active: manualActive ?? list.find(p => p.isPlaying) ?? list[0] ?? null
    property MprisPlayer manualActive

    function getIdentity(player: MprisPlayer): string {
        return player?.identity ?? "";
    }

    function getArtUrl(player: MprisPlayer): string {
        if (!player)
            return "";
        if (player.trackArtUrl)
            return player.trackArtUrl;

        const url = player.metadata["xesam:url"] ?? "";
        if (url && url.includes("youtube.com/watch")) {
            const match = url.match(/[?&]v=([\w-]{11})/);
            const id = match ? match[1] : null;
            return id ? "https://img.youtube.com/vi/" + id + "/hqdefault.jpg" : "";
        }
        return "";
    }

    Timer {
        running: active !== null
        interval: 1000
        triggeredOnStart: true
        repeat: true
        onTriggered: {
            if (active) active.positionChanged();
        }
    }

    function play(): void {
        if (active?.canPlay) active.play();
    }

    function pause(): void {
        if (active?.canPause) active.pause();
    }

    function togglePlaying(): void {
        if (active?.canTogglePlaying) active.togglePlaying();
    }

    function previous(): void {
        if (active?.canGoPrevious) active.previous();
    }

    function next(): void {
        if (active?.canGoNext) active.next();
    }

    function stop(): void {
        if (active) active.stop();
    }

    IpcHandler {
        target: "mpris"

        function getActive(prop: string): string {
            const p = root.active;
            return p ? (p[prop] ?? "Invalid property") : "No active player";
        }

        function listPlayers(): string {
            return root.list.map(p => p.identity ?? "Unknown").join("\n");
        }

        function play(): void { root.play(); }
        function pause(): void { root.pause(); }
        function playPause(): void { root.togglePlaying(); }
        function previous(): void { root.previous(); }
        function next(): void { root.next(); }
        function stop(): void { root.stop(); }
    }
}
