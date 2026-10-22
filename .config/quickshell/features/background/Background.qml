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
            // $1 = source video, $2 = poster jpg (positional args, no quoting issues)
            command = [
                "sh", "-c",
                'mkdir -p "$(dirname "$2")" && '
                + 'if [ ! -f "$2" ] || [ "$1" -nt "$2" ]; then '
                + 'ffmpeg -hide_banner -loglevel error -y -ss 0 -i "$1" -frames:v 1 -q:v 2 "$2" && echo ok; '
                + 'else echo cached; fi',
                "sh", bgUtil.normalizePath(path), poster
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
            readonly property string fileType: bgUtil.getBackgroundType(wallpaperPath)
            readonly property bool animates: fileType === "animated"
                && backgroundScope.animatedPath === bgUtil.normalizePath(wallpaperPath)
            readonly property string mediaType: fileType === "animated" && !animates ? "image" : fileType
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

            // Still wallpaper or video poster, crossfading on change. The poster
            // stays under the Video so focus switches never flash empty.
            CrossfadeImage {
                anchors.fill: parent
                z: 0
                readonly property string url: win.showStaticImage || win.mediaType === "animated" ? win.mediaUrl
                    : win.showPoster ? win.posterUrl : ""
                request: {
                    if (!url)
                        return null;
                    const clip = Settings.wallpaperClipFor(win.width, win.height, url);
                    return {
                        url: url,
                        clip: clip.width > 0 ? clip : null,
                        size: Settings.wallpaperSourceSizeFor(win.width, win.height, url) ?? null
                    };
                }
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
                // Fades in over the first frame already crossfaded in below
                opacity: win.mediaType === "animated" && status === AnimatedImage.Ready ? 1 : 0
                visible: opacity > 0
                Behavior on opacity {
                    NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                }
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

            // Only created for video wallpapers: an idle Video still started
            // QtMultimedia/ffmpeg and Vulkan (pulling in the lsfg-vk layer), ~14 MB.
            Loader {
                anchors.fill: parent
                z: 2
                active: win.showVideo
                sourceComponent: Video {
                    id: videoWallpaper
                    source: win.showVideo ? win.mediaUrl : ""
                    fillMode: VideoOutput.PreserveAspectCrop
                    loops: MediaPlayer.Infinite
                    muted: true
                    autoPlay: false
                    visible: win.showVideo

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
    }

    // Pixel size of the still image actually shown (wallpaper or video poster)
    // Set by the probe when the wallpaper really animates. Extension alone lies:
    // a still .webp went through AnimatedImage and skipped the crossfade.
    property string animatedPath: ""
    readonly property string stillPath: bgUtil.normalizePath(
        bgUtil.isVideo(Settings.backgroundImagePath) ? Settings.backgroundPosterPath : Settings.backgroundImagePath)
    onStillPathChanged: probeStillSize()

    function probeStillSize() {
        Settings.wallpaperPixelSize = Qt.size(0, 0);
        Settings.wallpaperPixelPath = "";
        animatedPath = "";
        const type = bgUtil.getBackgroundType(stillPath);
        if (!stillPath || (type !== "image" && type !== "animated"))
            return;
        sizeProbe.command = ["ffprobe", "-v", "error", "-select_streams", "v:0",
            "-show_entries", "stream=codec_name,width,height", "-of", "csv=p=0", stillPath];
        sizeProbe.running = true;
    }

    Process {
        id: sizeProbe
        stdout: StdioCollector {
            id: sizeOut
        }
        onExited: code => {
            // "codec,width,height", e.g. "webp_anim,1920,1080"
            const m = sizeOut.text.trim().match(/^(\w+),(\d+),(\d+)/);
            if (code === 0 && m) {
                Settings.wallpaperPixelSize = Qt.size(Number(m[2]), Number(m[3]));
                Settings.wallpaperPixelPath = backgroundScope.stillPath;
                if (m[1] === "webp_anim" || m[1] === "gif" || m[1] === "apng")
                    backgroundScope.animatedPath = backgroundScope.stillPath;
            }
        }
    }

    Component.onCompleted: {
        console.log("Background initialized");
        probeStillSize();
        if (bgUtil.isVideo(Settings.backgroundImagePath))
            posterEnsure.ensure(Settings.backgroundImagePath);
    }
}
