import QtQuick

/**
 * Glow - a soft light (shaders/glow.frag). Premultiplied, so it adds light
 * over whatever is behind the overlay.
 */
ShaderEffect {
    property color core: "#fbfde6"
    property color halo: "#c9dc7c"
    property real coreSize: 0.16

    blending: true
    fragmentShader: Qt.resolvedUrl("../shaders/glow.frag.qsb")
}
