#version 440
// A soft light: bright core, wide falloff. Used for workspace lights and the island seed.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 core;      // centre colour
    vec4 halo;      // falloff colour
    float coreSize; // 0..0.5 of the item
};

void main() {
    float d = length(qt_TexCoord0 - 0.5) * 2.0;           // 0 centre, 1 edge
    float c = smoothstep(coreSize * 2.0, coreSize * 2.0 * 0.4, d);
    float h = pow(max(0.0, 1.0 - d), 1.3) * halo.a;
    // premultiplied: core on top of the halo
    vec3 col = core.rgb * c + halo.rgb * h * (1.0 - c);
    float a = c + h * (1.0 - c);
    fragColor = vec4(col, a) * qt_Opacity;
}
