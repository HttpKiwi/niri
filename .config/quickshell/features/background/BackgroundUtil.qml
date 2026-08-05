pragma ComponentBehavior: Bound

import QtQuick
import qs.config

/**
 * BackgroundUtil - Wallpaper media type helpers
 */
QtObject {
    id: util

    function normalizePath(filePath) {
        if (!filePath)
            return "";
        const path = String(filePath);
        if (path.startsWith("file://"))
            return path.slice(7);
        return path;
    }

    function toUrl(filePath) {
        const path = normalizePath(filePath);
        if (!path)
            return "";
        if (String(filePath).startsWith("file://"))
            return String(filePath);
        return "file://" + path;
    }

    function extensionOf(filePath) {
        const path = normalizePath(filePath).toLowerCase();
        const dot = path.lastIndexOf(".");
        if (dot < 0)
            return "";
        return path.slice(dot + 1);
    }

    /**
     * @return "video" | "animated" | "image" | "unknown"
     */
    function getBackgroundType(filePath) {
        const ext = extensionOf(filePath);
        if (!ext)
            return "unknown";

        if (ext === "mp4" || ext === "webm" || ext === "mkv" || ext === "mov"
                || ext === "avi" || ext === "flv" || ext === "m4v")
            return "video";

        // Animated formats — WebP may be static; Background plays only when frameCount > 1
        if (ext === "gif" || ext === "apng" || ext === "webp")
            return "animated";

        if (ext === "png" || ext === "jpg" || ext === "jpeg" || ext === "bmp"
                || ext === "svg" || ext === "tiff" || ext === "tif")
            return "image";

        return "unknown";
    }

    function isVideo(filePath) {
        return getBackgroundType(filePath) === "video";
    }

    function isAnimated(filePath) {
        return getBackgroundType(filePath) === "animated";
    }

    function isStaticImage(filePath) {
        return getBackgroundType(filePath) === "image";
    }

    function posterPathFor(filePath) {
        const path = normalizePath(filePath);
        if (!path || !isVideo(path))
            return "";
        const base = path.split("/").pop();
        return `${Settings.wallpapersDir}/.posters/${base}.jpg`;
    }
}
