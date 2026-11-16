#version 440
// The whole backdrop in one pass: wallpaper crossfade, time-of-day grade,
// light shafts, procedural life (pollen, fireflies, rain) and the clock
// blended into the painting. Cell-based particles: O(1) per pixel, no CPU sim.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float mixAB;        // 0 = wallA, 1 = wallB
    vec4 rectA;         // cover crop for wallA: scale.xy, offset.xy
    vec4 rectB;
    float t;            // seconds
    vec2 res;           // window size in px
    vec4 warmColor;     // soft-light tint (golden hour)
    float warmAmt;
    vec4 coolColor;     // multiply tint (night)
    float coolAmt;
    float shafts;       // 0..1
    float pollen;       // 0..1
    float fireflies;    // 0..1
    float rain;         // 0..1
    vec4 clockRect;     // x, y, w, h in 0..1
    float clockNight;   // 0 = overlay cream, 1 = plain ember
};
layout(binding = 1) uniform sampler2D wallA;
layout(binding = 2) uniform sampler2D wallB;
layout(binding = 3) uniform sampler2D clockTex;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
vec2 hash2(vec2 p) { return vec2(hash(p), hash(p + 17.31)); }

vec3 softLight(vec3 b, vec3 s) { return (1.0 - 2.0 * s) * b * b + 2.0 * s * b; }
vec3 overlay(vec3 b, vec3 s) {
    return mix(2.0 * b * s, 1.0 - 2.0 * (1.0 - b) * (1.0 - s), step(0.5, b));
}
vec3 screenBlend(vec3 b, vec3 s) { return 1.0 - (1.0 - b) * (1.0 - s); }

// One particle per populated cell, kept inside its cell so no neighbour lookups.
float field(vec2 p, float cell, float density, float radiusPx, out float seed) {
    vec2 id = floor(p / cell);
    vec2 f = fract(p / cell);
    seed = hash(id);
    if (seed > density) return 0.0;
    vec2 c = 0.2 + 0.6 * hash2(id);
    float d = length((f - c) * cell) * res.y;
    return smoothstep(radiusPx, 0.0, d);
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec3 col = mix(texture(wallA, rectA.zw + uv * rectA.xy).rgb,
                   texture(wallB, rectB.zw + uv * rectB.xy).rgb, mixAB);

    // light shafts: three slanted bands, slowly breathing, fading downwards
    if (shafts > 0.0) {
        float d = uv.x * 0.966 - uv.y * 0.259;
        float b = smoothstep(0.035, 0.0, abs(d - 0.12)) * 0.10
                + smoothstep(0.035, 0.0, abs(d - 0.27)) * 0.08
                + smoothstep(0.030, 0.0, abs(d - 0.40)) * 0.06;
        b *= 1.0 - smoothstep(0.0, 0.85, uv.y);
        b *= 0.55 + 0.45 * sin(t * 0.35);
        col = screenBlend(col, vec3(0.94, 0.92, 0.75) * b * shafts);
    }

    // time of day
    col = mix(col, softLight(col, warmColor.rgb), warmAmt * (1.0 - 0.5 * uv.y));
    col = mix(col, col * coolColor.rgb, coolAmt);

    vec2 a = vec2(res.x / res.y, 1.0);
    float seed;

    if (pollen > 0.0) {
        vec2 p = uv * a + vec2(sin(t * 0.07) * 0.03, t * 0.012);
        float l = field(p, 0.07, 0.35, 1.6, seed);
        l *= 0.25 + 0.2 * sin(t * 1.3 + seed * 40.0);
        col = screenBlend(col, vec3(0.96, 0.94, 0.78) * l * pollen);
    }

    if (fireflies > 0.0) {
        vec2 p = uv * a;
        vec2 id = floor(p / 0.16);
        float s = hash(id + 3.7);
        if (s < 0.45) {
            vec2 wander = 0.5 + 0.28 * vec2(sin(t * 0.31 + s * 40.0), cos(t * 0.23 + s * 70.0));
            float d = length((fract(p / 0.16) - wander) * 0.16) * res.y;
            float pulse = max(0.0, sin(t * 0.9 + s * 50.0));
            float g = (smoothstep(14.0, 0.0, d) * 0.35 + smoothstep(2.5, 0.0, d)) * pulse;
            col += vec3(0.98, 0.80, 0.42) * g * fireflies;
        }
    }

    if (rain > 0.0) {
        vec2 p = vec2(uv.x * a.x + uv.y * 0.12, uv.y);
        float colW = 0.011;
        float cx = floor(p.x / colW);
        float r = hash(vec2(cx, 1.0));
        float y = fract(p.y * 0.8 - t * (1.1 + r * 0.6) + r * 10.0);
        float streak = smoothstep(0.06, 0.0, y) * step(0.55, r);
        float xin = abs(fract(p.x / colW) - 0.5) * colW * res.y;
        streak *= smoothstep(1.0, 0.0, xin);
        col *= 1.0 - 0.10 * rain;
        col = screenBlend(col, vec3(0.82, 0.88, 0.9) * streak * 0.22 * rain);
    }

    // clock painted into the scene
    vec2 cuv = (uv - clockRect.xy) / clockRect.zw;
    if (cuv.x >= 0.0 && cuv.y >= 0.0 && cuv.x <= 1.0 && cuv.y <= 1.0) {
        float ca = texture(clockTex, cuv).a;
        vec3 painted = mix(overlay(col, vec3(1.0, 0.965, 0.86)), vec3(0.94, 0.76, 0.42), clockNight);
        col = mix(col, painted, ca * mix(1.0, 0.38, clockNight));
    }

    fragColor = vec4(col, 1.0) * qt_Opacity;
}
