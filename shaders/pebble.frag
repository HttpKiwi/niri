#version 440
// The island's body: a rounded box whose edge drifts like the surface of a
// pond. Never exactly the same shape twice, never fully still. Rendered
// premultiplied, inset by `pad` px so the wobble can bulge outwards.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;      // the shape's size in px (the item is larger by pad on each side)
    float pad;
    vec4 radii;     // corner radii: top-left, top-right, bottom-right, bottom-left
    float amp;      // how far the edge wanders, px
    float t;        // seconds
    float seed;
    vec4 fillTop;    // fill gradient, top and bottom (straight alpha)
    vec4 fillBottom;
    vec4 edge;      // 1 px rim light
};

void main() {
    vec2 full = size + 2.0 * pad;
    vec2 p = qt_TexCoord0 * full - full * 0.5;   // px from the centre

    float r = p.x < 0.0 ? (p.y < 0.0 ? radii.x : radii.w) : (p.y < 0.0 ? radii.y : radii.z);
    r = min(r, min(size.x, size.y) * 0.5);
    vec2 q = abs(p) - size * 0.5 + r;
    float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;

    // slow, low-frequency drift scaled to the shape so a pill and the menu both feel liquid
    vec2 u = p / max(size, vec2(1.0));
    float w = sin(u.x * 5.0 + t * 0.55 + seed) * sin(u.y * 5.0 - t * 0.43 + seed * 1.7)
            + 0.6 * sin((u.x - u.y) * 3.5 + t * 0.31 + seed * 2.3)
            + 0.3 * sin(u.x * 9.0 - t * 0.8 + seed * 0.6);
    d -= amp * w * 0.55;

    float fw = max(fwidth(d), 0.0001);
    float a = clamp(0.5 - d / fw, 0.0, 1.0);

    vec4 fill = mix(fillTop, fillBottom, clamp(qt_TexCoord0.y, 0.0, 1.0));
    float rim = clamp(1.0 + d, 0.0, 1.0) * edge.a;
    vec3 rgb = mix(fill.rgb, edge.rgb, rim);
    float alpha = a * fill.a;
    fragColor = vec4(rgb * alpha, alpha) * qt_Opacity;
}
