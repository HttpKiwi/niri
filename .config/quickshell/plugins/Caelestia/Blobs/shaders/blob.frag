#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float paddedX;
    float paddedY;
    float paddedW;
    float paddedH;
    float smoothFactor;
    int rectCount;
    int myIndex;
    vec4 color;
    int hasInverted;
    float invertedRadius;
    vec4 invertedOuter;
    vec4 invertedInner;
    vec4 rectData[80];
    float chromeTime;
    float chromeCellSize;
    float chromeDotSize;
    float chromeAnimSpeed;
    float chromeIntensity;
    float chromeScreenW;
    float chromeScreenH;
    float chromeOriginX;
    float chromeOriginY;
    int chromeEnabled;
    float _chromePad0;
    float _chromePad1;
    vec4 chromeColor1;
    vec4 chromeColor2;
    vec4 chromeColor3;
    vec4 chromeBaseColor;
};

// Flex Volume–style aurora on dark chrome:
//   - Most pixels = pure surfaceBase
//   - Organic ribbons via multi-stage domain warping (no planar diagonal waves)
//   - Light dot-matrix mesh on top

// Nested domain warp — breaks linear wave fronts into flowing liquid paths
vec2 domainWarp(vec2 p, float t) {
    // Stage 1
    vec2 q = vec2(
        sin(p.y * 1.4 + t * 0.28) + sin(p.x * 0.7 - t * 0.17) * 0.6,
        cos(p.x * 1.3 - t * 0.22) + cos(p.y * 0.65 + t * 0.19) * 0.6
    );
    // Stage 2 — warp the warp
    vec2 r = vec2(
        sin((p.x + q.y) * 1.6 + t * 0.14) * 0.85,
        cos((p.y + q.x) * 1.55 - t * 0.11) * 0.85
    );
    // Stage 3 — high viscosity meander
    return vec2(
        sin((p.x + r.y * 1.3) * 1.35 - t * 0.09) * 0.7,
        cos((p.y + r.x * 1.3) * 1.35 + t * 0.1) * 0.7
    );
}

// Organic ribbon: field lives entirely in warped space, so paths curve and split
float organicRibbon(vec2 p, float t, float scale, float phase) {
    vec2 w = domainWarp(p * scale + vec2(phase * 0.37, phase * 0.21), t + phase);

    // Value from warped domain only — not sin(ax+by), so no diagonal fronts
    float field = sin(w.x * 2.4 + phase) * cos(w.y * 2.1 - phase * 0.6);
    // Second warped sample for thicker/thinner variation along the path
    vec2 w2 = domainWarp(p * scale * 1.3 - w * 0.4 + phase, t * 0.7 - phase);
    field = field * 0.65 + sin(w2.x * 1.8 - w2.y * 1.2) * 0.35;

    // Narrow soft peaks only
    return pow(smoothstep(0.55, 0.92, field), 1.3);
}

vec3 chromeSurfaceColor(vec2 scenePixel) {
    vec2 pixel = scenePixel - vec2(chromeOriginX, chromeOriginY);
    vec2 uv = pixel / vec2(max(chromeScreenW, 1.0), max(chromeScreenH, 1.0));
    vec2 p = uv;
    p.x *= chromeScreenW / max(chromeScreenH, 1.0);
    p *= 1.4;

    float t = chromeTime * chromeAnimSpeed;

    vec3 surface = chromeBaseColor.rgb;
    vec3 primary = chromeColor1.rgb;
    vec3 secondary = chromeColor2.rgb;
    vec3 tertiary = chromeColor3.rgb;

    // Independent organic streams (different scale/phase → non-parallel paths)
    float r1 = organicRibbon(p, t * 0.85, 1.0, 0.0);
    float r2 = organicRibbon(p, t * 1.05, 1.25, 2.7);
    float r3 = organicRibbon(p, t * 0.7, 0.8, 5.1);

    float strength = clamp(chromeIntensity, 0.0, 1.0);

    vec3 col = surface;
    col = mix(col, primary, r1 * strength);
    col = mix(col, secondary, r2 * strength * 0.85);
    col = mix(col, tertiary, r3 * strength * 0.7);

    // Soft halo into the dark base
    float halo = max(max(r1, r2), r3);
    halo = pow(halo, 0.5) * strength * 0.22;
    vec3 haloColor = primary * r1 + secondary * r2 + tertiary * r3;
    float haloW = max(r1 + r2 + r3, 0.001);
    col = mix(col, haloColor / haloW, halo);

    // Light dot-matrix mesh
    vec2 cell = mod(pixel, chromeCellSize);
    float dist = length(cell - vec2(chromeCellSize * 0.5));
    float radius = chromeDotSize * chromeCellSize * 0.5;
    float dotMask = 1.0 - smoothstep(radius * 0.55, radius, dist);
    col = mix(col, col + vec3(0.08), dotMask * 0.45);

    return col;
}

float sdRoundedBox(vec2 p, vec2 center, vec2 halfSize, float radius) {
    vec2 d = abs(p - center) - halfSize + vec2(radius);
    return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0) - radius;
}

float sdRoundedBox4(vec2 p, vec2 center, vec2 halfSize, vec4 r) {
    p -= center;
    r.xy = (p.x > 0.0) ? r.xy : r.wz;
    r.x  = (p.y > 0.0) ? r.y : r.x;
    vec2 q = abs(p) - halfSize + r.x;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r.x;
}

float sdBox(vec2 p, vec2 center, vec2 halfSize) {
    vec2 d = abs(p - center) - halfSize;
    return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0);
}

float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * h * k * (1.0/6.0);
}

float smax(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return max(a, b) + h * h * h * k * (1.0/6.0);
}

float smaxSharpA(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    float blend = h * h * h * k * (1.0/6.0);
    blend *= smoothstep(0.0, k * 0.5, -a);
    return max(a, b) + blend;
}

void main() {
    vec2 pixel = vec2(paddedX, paddedY) + qt_TexCoord0 * vec2(paddedW, paddedH);

    float dArr[16];
    int owner = -2;
    float minDist = 1e10;

    for (int i = 0; i < rectCount; i++) {
        vec4 rect = rectData[i * 5];
        vec4 props = rectData[i * 5 + 1];
        vec4 invDm = rectData[i * 5 + 2];
        vec4 sh = rectData[i * 5 + 3];
        vec4 radii = rectData[i * 5 + 4];

        vec2 center = rect.xy + props.yz;

        vec2 extent = sh.xy + vec2(smoothFactor * 1.5);
        if (abs(pixel.x - center.x) > extent.x || abs(pixel.y - center.y) > extent.y) {
            dArr[i] = 1e10;
            continue;
        }

        mat2 invDeform = mat2(invDm.xy, invDm.zw);
        vec2 transformedPixel = center + invDeform * (pixel - center);

        float d = sdRoundedBox4(transformedPixel, center, rect.zw, radii);

        d *= max(props.w, 0.01);

        if (hasInverted != 0) {
            vec2 screenHalf = sh.xy;

            float distY0 = (center.y + screenHalf.y) - (invertedInner.y - invertedInner.w);
            float distY1 = (invertedInner.y + invertedInner.w) - (center.y - screenHalf.y);
            float distX0 = (center.x + screenHalf.x) - (invertedInner.x - invertedInner.z);
            float distX1 = (invertedInner.x + invertedInner.z) - (center.x - screenHalf.x);

            float yProx = 1.0 - min(
                smoothstep(0.0, smoothFactor, distY0),
                smoothstep(0.0, smoothFactor, distY1)
            );
            float xProx = 1.0 - min(
                smoothstep(0.0, smoothFactor, distX0),
                smoothstep(0.0, smoothFactor, distX1)
            );

            vec2 q = abs(pixel - center) - screenHalf;
            vec2 qp = max(q, vec2(0.0));
            float cornerLen = length(qp);

            float gradX = qp.x / max(cornerLen, 0.001);
            float gradY = qp.y / max(cornerLen, 0.001);

            float faceY = smoothstep(-4.0, 4.0, q.y - q.x);
            float faceX = 1.0 - faceY;

            float t = smoothstep(0.0, 2.0, cornerLen);
            float xWeight = mix(faceX, gradX, t);
            float yWeight = mix(faceY, gradY, t);

            float boost = 3.0;
            float scale = 1.0 + (xProx * xWeight + yProx * yWeight) * boost;
            d *= scale;
        }

        dArr[i] = d;
        if (d < smoothFactor && d < minDist) {
            minDist = d;
            owner = i;
        }
    }

    float mergedSdf = 1e10;
    for (int i = 0; i < rectCount; i++) {
        mergedSdf = min(mergedSdf, dArr[i]);
    }

    for (int i = 0; i < rectCount; i++) {
        if (dArr[i] >= 1e9)
            continue;
        int excludeMask = floatBitsToInt(rectData[i * 5 + 1].x);
        for (int j = i + 1; j < rectCount; j++) {
            if (dArr[j] >= 1e9)
                continue;
            if ((excludeMask & (1 << j)) != 0)
                continue;
            if (abs(dArr[i] - dArr[j]) >= smoothFactor)
                continue;
            mergedSdf = min(mergedSdf, smin(dArr[i], dArr[j], smoothFactor));
        }
    }

    if (hasInverted != 0) {
        float dOuter = sdBox(pixel, invertedOuter.xy, invertedOuter.zw) - 1.0;
        float dInner = sdRoundedBox(pixel, invertedInner.xy, invertedInner.zw, invertedRadius);

        float innerTop = invertedInner.y - invertedInner.w;
        float innerBot = invertedInner.y + invertedInner.w;
        float innerLeft = invertedInner.x - invertedInner.z;
        float innerRight = invertedInner.x + invertedInner.z;
        float outerTop = invertedOuter.y - invertedOuter.w;
        float outerBot = invertedOuter.y + invertedOuter.w;
        float outerLeft = invertedOuter.x - invertedOuter.z;
        float outerRight = invertedOuter.x + invertedOuter.z;

        float sinkValue = 0.0;
        for (int i = 0; i < rectCount; i++) {
            vec4 rect = rectData[i * 5];
            vec4 sinkProps = rectData[i * 5 + 1];
            vec2 sinkSh = rectData[i * 5 + 3].xy;

            vec2 ctr = rect.xy + sinkProps.yz;

            float preOff = smoothFactor * (1.0/6.0);

            float topPen = clamp(innerTop - (ctr.y + sinkSh.y) - preOff, 0.0, innerTop - outerTop);
            float botPen = clamp((ctr.y - sinkSh.y) - innerBot - preOff, 0.0, outerBot - innerBot);
            float leftPen = clamp(innerLeft - (ctr.x + sinkSh.x) - preOff, 0.0, innerLeft - outerLeft);
            float rightPen = clamp((ctr.x - sinkSh.x) - innerRight - preOff, 0.0, outerRight - innerRight);

            float hLat = max(abs(pixel.x - ctr.x) - sinkSh.x, 0.0);
            float vLat = max(abs(pixel.y - ctr.y) - sinkSh.y, 0.0);

            float topZone = 1.0 - smoothstep(innerTop, innerTop + smoothFactor, pixel.y);
            float botZone = smoothstep(innerBot - smoothFactor, innerBot, pixel.y);
            float leftZone = 1.0 - smoothstep(innerLeft, innerLeft + smoothFactor, pixel.x);
            float rightZone = smoothstep(innerRight - smoothFactor, innerRight, pixel.x);

            float s = smoothFactor * 2.0;
            float sink = max(
                max(topPen * smoothstep(s, 0.0, hLat) * topZone,
                    botPen * smoothstep(s, 0.0, hLat) * botZone),
                max(leftPen * smoothstep(s, 0.0, vLat) * leftZone,
                    rightPen * smoothstep(s, 0.0, vLat) * rightZone)
            );
            sinkValue = max(sinkValue, sink);
        }

        dInner -= sinkValue;

        float dFrame = smaxSharpA(dOuter, -dInner, smoothFactor);

        mergedSdf = smin(mergedSdf, dFrame, smoothFactor);
        if (dFrame < minDist) {
            owner = -1;
        }
    }

    if (owner != myIndex && mergedSdf > smoothFactor)
        discard;

    float fw = fwidth(mergedSdf);
    float alpha = 1.0 - smoothstep(-fw, fw, mergedSdf);
    vec3 surfaceRgb = color.rgb;
    if (chromeEnabled != 0) {
        surfaceRgb = chromeSurfaceColor(pixel);
    }
    fragColor = vec4(surfaceRgb * alpha, alpha) * qt_Opacity;
}
