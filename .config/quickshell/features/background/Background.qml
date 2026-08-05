pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.core
import "."

Scope {
    id: backgroundScope

    BackgroundUtil {
        id: bgUtil
    }

    // Ensure video posters exist for matugen / lock / inactive monitors
    Process {
        id: posterEnsure
        running: false
        property string pendingPath: ""

        stdout: SplitParser {
            onRead: data => console.log("Background poster:", data)
        }
        stderr: SplitParser {
            onRead: data => console.log("Background poster:", data)
        }

        function ensure(path) {
            if (!bgUtil.isVideo(path))
                return;
            const poster = bgUtil.posterPathFor(path);
            if (!poster)
                return;
            pendingPath = path;
            command = [
                "sh", "-c",
                `mkdir -p "$(dirname '${poster}')" && `
                + `if [ ! -f '${poster}' ] || [ '${bgUtil.normalizePath(path)}' -nt '${poster}' ]; then `
                + `ffmpeg -hide_banner -loglevel error -y -ss 0 -i '${bgUtil.normalizePath(path)}' `
                + `-frames:v 1 -q:v 2 '${poster}' && echo ok; `
                + `else echo cached; fi`
            ];
            running = false;
            running = true;
        }

        onRunningChanged: {
            if (running || !pendingPath)
                return;
            const poster = bgUtil.posterPathFor(pendingPath);
            if (poster)
                Settings.backgroundPosterPath = "file://" + poster;
            pendingPath = "";
        }
    }

    Connections {
        target: Settings
        function onBackgroundImagePathChanged() {
            const path = Settings.backgroundImagePath;
            if (bgUtil.isVideo(path))
                posterEnsure.ensure(path);
            else
                Settings.backgroundPosterPath = "";
        }
    }

    Variants {
        model: Quickshell.screens || []

        PanelWindow {
            id: win

            required property var modelData

            readonly property string wallpaperPath: Settings.backgroundImagePath
            readonly property string mediaType: bgUtil.getBackgroundType(wallpaperPath)
            readonly property bool hasMedia: wallpaperPath !== ""
            readonly property string posterUrl: Settings.backgroundPosterPath
                || (bgUtil.isVideo(wallpaperPath) ? bgUtil.toUrl(bgUtil.posterPathFor(wallpaperPath)) : "")
            readonly property string mediaUrl: bgUtil.toUrl(wallpaperPath)

            readonly property bool allowMotion: Settings.animatedWallpapersEnabled
                && !LockState.locked
                && !LockState.engaging

            readonly property bool showVideo: hasMedia && mediaType === "video"
            readonly property bool playVideo: showVideo && allowMotion
            // Poster under video until a frame exists; static images as usual
            readonly property bool showPoster: showVideo
            readonly property bool showStaticImage: hasMedia && mediaType === "image"

            visible: true
            screen: modelData || Quickshell.screens[0]
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "overview"
            WlrLayershell.layer: WlrLayer.Background
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            Rectangle {
                anchors.fill: parent
                color: Settings.backgroundColor
                visible: !win.hasMedia
            }

            // Static images
            Image {
                anchors.fill: parent
                source: win.showStaticImage ? win.mediaUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: win.showStaticImage
                z: 0
            }

            // Video poster — stays under the Video so focus switches never flash empty
            Image {
                anchors.fill: parent
                source: win.showPoster ? win.posterUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: win.showPoster
                z: 0
            }

            // GIF / APNG / animated WebP
            // Wallpapers often encode loop=1; Qt's AnimatedImage then stops forever.
            // Drive frames ourselves so looping never depends on the file's loop count.
            AnimatedImage {
                id: animImage
                anchors.fill: parent
                source: win.mediaType === "animated" ? win.mediaUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                visible: win.mediaType === "animated"
                z: 1
                // Never use built-in playback — it honors finite loop counts
                playing: false

                readonly property bool wantPlay: win.mediaType === "animated"
                    && win.allowMotion
                    && status === AnimatedImage.Ready
                    && frameCount > 1

                // ~24fps default; cozycabininthewoods.webp averages ~41ms/frame
                readonly property int frameIntervalMs: 40

                onSourceChanged: currentFrame = 0
                onWantPlayChanged: {
                    if (!wantPlay)
                        return;
                    if (currentFrame >= frameCount)
                        currentFrame = 0;
                }

                Timer {
                    id: animFrameTicker
                    interval: animImage.frameIntervalMs
                    running: animImage.wantPlay
                    repeat: true
                    onTriggered: {
                        const last = animImage.frameCount - 1;
                        if (last < 1)
                            return;
                        animImage.currentFrame = animImage.currentFrame >= last
                            ? 0
                            : animImage.currentFrame + 1;
                    }
                }
            }

            // Keep source loaded on every screen; play/pause only.
            Video {
                id: videoWallpaper
                anchors.fill: parent
                source: win.showVideo ? win.mediaUrl : ""
                fillMode: VideoOutput.PreserveAspectCrop
                loops: MediaPlayer.Infinite
                muted: true
                autoPlay: false
                visible: win.showVideo
                z: 2

                function syncPlayback() {
                    if (!win.showVideo) {
                        stop();
                        return;
                    }
                    if (win.playVideo) {
                        if (playbackState !== MediaPlayer.PlayingState)
                            play();
                    } else if (playbackState === MediaPlayer.PlayingState) {
                        pause();
                    }
                }

                onSourceChanged: Qt.callLater(syncPlayback)

                onPlaybackStateChanged: {
                    if (!win.showVideo)
                        return;
                    // Resume from pause/stop whenever motion is allowed again
                    if (win.playVideo && playbackState !== MediaPlayer.PlayingState)
                        Qt.callLater(play);
                    else if (!win.playVideo && playbackState === MediaPlayer.PlayingState)
                        Qt.callLater(pause);
                }

                onErrorChanged: {
                    if (error !== MediaPlayer.NoError)
                        console.warn("Background video error:", errorString);
                }

                Connections {
                    target: win
                    function onPlayVideoChanged() { videoWallpaper.syncPlayback() }
                    function onShowVideoChanged() { videoWallpaper.syncPlayback() }
                    function onAllowMotionChanged() { videoWallpaper.syncPlayback() }
                }

                Connections {
                    target: LockState
                    function onLockedChanged() { videoWallpaper.syncPlayback() }
                    function onEngagingChanged() { videoWallpaper.syncPlayback() }
                }

                Component.onCompleted: syncPlayback()
            }
        }
    }

    Component.onCompleted: {
        console.log("Background initialized");
        if (bgUtil.isVideo(Settings.backgroundImagePath))
            posterEnsure.ensure(Settings.backgroundImagePath);
    }
}
