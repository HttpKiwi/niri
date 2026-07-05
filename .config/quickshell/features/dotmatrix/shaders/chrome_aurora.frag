#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float time;
    float cellSize;
    float dotSize;
    float animSpeed;
    float intensity;
    float itemWidth;
    float itemHeight;
    float screenWidth;
    float screenHeight;
    float offsetX;
    float offsetY;
    vec4 color1;
    vec4 color2;
    vec4 color3;
    vec4 baseColor;
};

vec2 domainWarp(vec2 p, float t) {
    vec2 q = vec2(
        sin(p.y * 1.4 + t * 0.28) + sin(p.x * 0.7 - t * 0.17) * 0.6,
        cos(p.x * 1.3 - t * 0.22) + cos(p.y * 0.65 + t * 0.19) * 0.6
    );
    vec2 r = vec2(
        sin((p.x + q.y) * 1.6 + t * 0.14) * 0.85,
        cos((p.y + q.x) * 1.55 - t * 0.11) * 0.85
    );
    return vec2(
        sin((p.x + r.y * 1.3) * 1.35 - t * 0.09) * 0.7,
        cos((p.y + r.x * 1.3) * 1.35 + t * 0.1) * 0.7
    );
}

float organicRibbon(vec2 p, float t, float scale, float phase) {
    vec2 w = domainWarp(p * scale + vec2(phase * 0.37, phase * 0.21), t + phase);
    float field = sin(w.x * 2.4 + phase) * cos(w.y * 2.1 - phase * 0.6);
    vec2 w2 = domainWarp(p * scale * 1.3 - w * 0.4 + phase, t * 0.7 - phase);
    field = field * 0.65 + sin(w2.x * 1.8 - w2.y * 1.2) * 0.35;
    return pow(smoothstep(0.55, 0.92, field), 1.3);
}

void main() {
    vec2 pixel = vec2(offsetX, offsetY) + qt_TexCoord0 * vec2(itemWidth, itemHeight);
    vec2 uv = pixel / vec2(max(screenWidth, 1.0), max(screenHeight, 1.0));
    vec2 p = uv;
    p.x *= screenWidth / max(screenHeight, 1.0);
    p *= 1.4;

    float t = time * animSpeed;

    vec3 surface = baseColor.rgb;
    vec3 primary = color1.rgb;
    vec3 secondary = color2.rgb;
    vec3 tertiary = color3.rgb;

    float r1 = organicRibbon(p, t * 0.85, 1.0, 0.0);
    float r2 = organicRibbon(p, t * 1.05, 1.25, 2.7);
    float r3 = organicRibbon(p, t * 0.7, 0.8, 5.1);

    float strength = clamp(intensity, 0.0, 1.0);

    vec3 col = surface;
    col = mix(col, primary, r1 * strength);
    col = mix(col, secondary, r2 * strength * 0.85);
    col = mix(col, tertiary, r3 * strength * 0.7);

    float halo = max(max(r1, r2), r3);
    halo = pow(halo, 0.5) * strength * 0.22;
    vec3 haloColor = primary * r1 + secondary * r2 + tertiary * r3;
    float haloW = max(r1 + r2 + r3, 0.001);
    col = mix(col, haloColor / haloW, halo);

    vec2 cell = mod(pixel, cellSize);
    float dist = length(cell - vec2(cellSize * 0.5));
    float radius = dotSize * cellSize * 0.5;
    float dotMask = 1.0 - smoothstep(radius * 0.55, radius, dist);
    col = mix(col, col + vec3(0.08), dotMask * 0.45);

    fragColor = vec4(col, 1.0) * qt_Opacity;
}
