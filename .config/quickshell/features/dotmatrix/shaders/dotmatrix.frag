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

vec2 liquidWarp(vec2 p, float t) {
    vec2 q;
    q.x = sin(p.x * 1.1 + p.y * 1.3 + t * 0.35);
    q.y = cos(p.x * 1.4 - p.y * 1.1 + t * 0.25);
    vec2 r;
    r.x = sin((p.x + q.y) * 1.8 + t * 0.18) * 0.5;
    r.y = cos((p.y + q.x) * 1.8 + t * 0.12) * 0.5;
    vec2 s;
    s.x = sin((p.x + r.y * 1.4) * 1.6 - t * 0.08) * 0.45;
    s.y = cos((p.y + r.x * 1.4) * 1.6 + t * 0.14) * 0.45;
    return s;
}

float getRibbon(vec2 p, float t, float speed, float freq, float phaseShift, out vec2 w) {
    w = liquidWarp(p, t * speed);
    float lfo = sin(p.x * 0.6 - t * 0.06) * 1.8 + phaseShift;
    float val = sin((p.x + w.x * 2.4) * freq + (p.y + w.y * 2.4) * freq + lfo);
    return smoothstep(0.71, 0.74, abs(val));
}

vec3 iridescence(float thickness, vec3 baseCol) {
    vec3 iridColor;
    iridColor.r = sin(thickness * 6.28318) * 0.5 + 0.5;
    iridColor.g = sin(thickness * 6.28318 + 2.09439) * 0.5 + 0.5;
    iridColor.b = sin(thickness * 6.28318 + 4.18879) * 0.5 + 0.5;
    return mix(baseCol, iridColor, 0.48);
}

void main() {
    // Screen-space pixel (top-left origin), matching blob chrome coordinates
    vec2 pixel = vec2(offsetX, offsetY) + qt_TexCoord0 * vec2(itemWidth, itemHeight);
    vec2 uv = pixel / vec2(max(screenWidth, 1.0), max(screenHeight, 1.0));

    vec2 p = uv;
    p.x *= screenWidth / max(screenHeight, 1.0);
    p *= 1.8;

    float t = time * animSpeed;

    vec3 col1 = (length(color1.rgb) > 0.0) ? color1.rgb : vec3(0.78, 0.45, 1.0);
    vec3 col2 = (length(color2.rgb) > 0.0) ? color2.rgb : vec3(0.25, 0.75, 1.0);
    vec3 col3 = (length(color3.rgb) > 0.0) ? color3.rgb : vec3(0.95, 0.60, 0.30);
    vec3 bgBase = (length(baseColor.rgb) > 0.0) ? baseColor.rgb : vec3(0.005, 0.005, 0.010);

    vec3 bg = bgBase * 0.04;
    vec3 lightDir = normalize(vec3(0.5, 0.5, 0.8));
    vec3 finalLiquid = bg;

    vec2 w1, w2, w3;
    float ribbon1 = getRibbon(p * 1.5, t, 0.82, 1.9, 1.4, w1);
    float ribbon2 = getRibbon(p * 1.2, t * 0.9, 0.74, 1.6, 5.8, w2);
    float ribbon3 = getRibbon(p * 2.0, t * 1.1, 0.90, 2.3, 3.1, w3);

    if (ribbon3 > 0.01) {
        vec3 r3Color = iridescence(w3.x * 2.5 + t * 0.1, col3);
        vec3 normal = normalize(vec3(w3.x * 2.0, w3.y * 2.0, 1.0));
        float spec = pow(max(dot(normal, lightDir), 0.0), 14.0) * 0.35;
        finalLiquid = mix(finalLiquid, r3Color + vec3(spec), ribbon3 * 0.35);
    }

    if (ribbon2 > 0.01) {
        vec3 r2Color = iridescence(w2.y * 2.5 - t * 0.1, col2);
        vec3 normal = normalize(vec3(w2.x * 2.0, w2.y * 2.0, 1.0));
        float spec = pow(max(dot(normal, lightDir), 0.0), 14.0) * 0.35;
        finalLiquid = mix(finalLiquid, r2Color + vec3(spec), ribbon2 * 0.45);
    }

    if (ribbon1 > 0.01) {
        vec3 r1Color = iridescence(w1.x * 2.0 + w1.y * 2.0, col1);
        vec3 normal = normalize(vec3(w1.x * 2.0, w1.y * 2.0, 1.0));
        float spec = pow(max(dot(normal, lightDir), 0.0), 14.0) * 0.35;
        finalLiquid = mix(finalLiquid, r1Color + vec3(spec), ribbon1);
    }

    vec2 cell = mod(pixel, cellSize);
    float dist = length(cell - vec2(cellSize * 0.5));
    float radius = dotSize * cellSize * 0.5;
    float dotMask = 1.0 - smoothstep(radius * 0.7, radius, dist);
    finalLiquid = mix(finalLiquid, finalLiquid * 0.82, dotMask * intensity);

    finalLiquid = 1.0 - exp(-finalLiquid * 1.8);
    fragColor = vec4(finalLiquid, 1.0) * qt_Opacity;
}
