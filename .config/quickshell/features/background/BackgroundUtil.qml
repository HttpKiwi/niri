pragma ComponentBehavior: Bound

import QtQuick

/**
 * BackgroundUtil - Utility functions for background file handling
 * Provides file type detection and format validation
 */

QtObject {
    id: util

    /**
     * Detects the type of background file based on extension
     * @param filePath - Full path to the file
     * @return "animated", "video", "image", or "unknown"
     */
    function getBackgroundType(filePath) {
        if (!filePath || filePath === "") {
            return "unknown"
        }

        const lowerPath = filePath.toLowerCase()

        // Animated image formats
        if (lowerPath.endsWith(".gif") ||
            lowerPath.endsWith(".webp") ||
            lowerPath.endsWith(".apng")) {
            return "animated"
        }

        // Video formats
        if (lowerPath.endsWith(".mp4") ||
            lowerPath.endsWith(".mkv") ||
            lowerPath.endsWith(".mov") ||
            lowerPath.endsWith(".webm") ||
            lowerPath.endsWith(".flv") ||
            lowerPath.endsWith(".avi")) {
            return "video"
        }

        // Static image formats
        if (lowerPath.endsWith(".png") ||
            lowerPath.endsWith(".jpg") ||
            lowerPath.endsWith(".jpeg") ||
            lowerPath.endsWith(".bmp") ||
            lowerPath.endsWith(".svg") ||
            lowerPath.endsWith(".tiff")) {
            return "image"
        }

        return "unknown"
    }

    /**
     * Checks if a file is an animated format
     * @param filePath - Full path to the file
     * @return true if file is animated (gif, webp, apng)
     */
    function isAnimated(filePath) {
        return getBackgroundType(filePath) === "animated"
    }

    /**
     * Checks if a file is a video format
     * @param filePath - Full path to the file
     * @return true if file is a video
     */
    function isVideo(filePath) {
        return getBackgroundType(filePath) === "video"
    }

    /**
     * Checks if a file is a static image format
     * @param filePath - Full path to the file
     * @return true if file is a static image
     */
    function isStaticImage(filePath) {
        return getBackgroundType(filePath) === "image"
    }

    /**
     * Get MIME type for file
     * @param filePath - Full path to the file
     * @return MIME type string
     */
    function getMimeType(filePath) {
        if (!filePath || filePath === "") {
            return "unknown"
        }

        const type = getBackgroundType(filePath)
        const ext = filePath.split('.').pop().toLowerCase()

        if (type === "video") {
            const videoMimes = {
                "mp4": "video/mp4",
                "webm": "video/webm",
                "mkv": "video/x-matroska",
                "mov": "video/quicktime",
                "avi": "video/x-msvideo",
                "flv": "video/x-flv"
            }
            return videoMimes[ext] || "video/mp4"
        }

        if (type === "animated" || type === "image") {
            const imageMimes = {
                "gif": "image/gif",
                "webp": "image/webp",
                "apng": "image/apng",
                "png": "image/png",
                "jpg": "image/jpeg",
                "jpeg": "image/jpeg",
                "bmp": "image/bmp",
                "svg": "image/svg+xml",
                "tiff": "image/tiff"
            }
            return imageMimes[ext] || "image/png"
        }

        return "unknown"
    }

    /**
     * Extract file extension
     * @param filePath - Full path to the file
     * @return file extension without dot
     */
    function getExtension(filePath) {
        if (!filePath || filePath === "") {
            return ""
        }
        const parts = filePath.split('.')
        return parts.length > 1 ? parts[parts.length - 1].toLowerCase() : ""
    }

    Component.onCompleted: {
        console.log("BackgroundUtil utility initialized")
    }
}
