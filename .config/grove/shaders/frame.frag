#version 440
// The screen's rim: black outside a rounded rectangle whose edge drifts a pixel
// or two. Evaluated in screen coordinates so the four edge strips join up.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 screenSize;
    vec2 origin;      // this strip's top-left, screen px
    vec2 stripSize;
    float radius;
    float inset;
    float amp;
    float t;
};

void main() {
    vec2 p = origin + qt_TexCoord0 * stripSize;
    vec2 q = abs(p - screenSize * 0.5) - screenSize * 0.5 + radius;
    float sd = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;   // < 0 inside

    float w = sin(p.x / 230.0 + t * 0.45) + sin(p.y / 170.0 - t * 0.37)
            + 0.6 * sin((p.x + p.y) / 120.0 + t * 0.29 + 1.7)
            + 0.4 * sin((p.x - p.y) / 70.0 - t * 0.6);
    float e = inset + amp * (w * 0.3 + 0.5);   // edge depth in px, 0..~2.8

    float d = sd + e;                          // > 0: black
    float a = clamp(0.5 + d / max(fwidth(d), 0.0001), 0.0, 1.0);
    fragColor = vec4(0.0, 0.0, 0.0, a) * qt_Opacity;
}
