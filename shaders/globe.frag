#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;
uniform float uTime;
uniform vec2 uTouch;
uniform sampler2D uTexture;

out vec4 fragColor;

const float PI = 3.14159265359;

float hash(vec2 p) {
    p = fract(p * vec2(123.39, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float SimplexNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float crackPattern(vec2 uv) {
    vec2 p = uv * 12.0;
    float n = SimplexNoise(p + vec2(uTime * 0.05));
    float crack = abs(sin(n * PI * 6.0));
    return smoothstep(0.0, 0.15, crack);
}

void main() {
    vec2 st = (FlutterFragCoord().xy - 0.5 * uResolution) / (min(uResolution.x, uResolution.y) * 0.5);

    float radius = 0.85;
    float dist = length(st);

    if (dist > radius) {
        fragColor = vec4(0.0);
        return;
    }

    // 1. Normal 3D Permukaan Bola
    float z = sqrt(radius * radius - dist * dist);
    vec3 normal = normalize(vec3(st.x, st.y, z));

    // 2. Pemetaan Spherical UV + Rotasi Touch Drag
    float lon = atan(normal.z, normal.x) - uTime * 0.3 + uTouch.x;
    float lat = asin(clamp(normal.y / radius, -1.0, 1.0)) + uTouch.y;

    vec2 uv = vec2(
        fract(0.5 - lon / (2.0 * PI)),
        clamp(0.5 + lat / PI, 0.0, 1.0)
    );

    // 3. Lighting Emas 3D
    vec3 lightDir1 = normalize(vec3(-0.8, 0.8, 1.0));
    vec3 lightDir2 = normalize(vec3(0.8, -0.5, 0.5));

    float diff1 = max(dot(normal, lightDir1), 0.0);
    float diff2 = max(dot(normal, lightDir2), 0.0);

    vec3 viewDir = vec3(0.0, 0.0, 1.0);
    vec3 reflectDir = reflect(-lightDir1, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 40.0);

    vec3 goldBase = vec3(1.0, 0.80, 0.22);
    vec3 goldDark = vec3(0.35, 0.18, 0.02);
    vec3 goldHighlight = vec3(1.0, 0.95, 0.75);

    vec3 goldColor = mix(goldDark, goldBase, diff1 + diff2 * 0.3) + goldHighlight * spec * 0.9;

    // 4. Texture & Cracks Blend
    float crack = crackPattern(uv);
    goldColor = mix(vec3(0.05, 0.03, 0.02), goldColor, crack);

    vec4 texColor = texture(uTexture, uv);
    vec3 finalColor = mix(goldColor, texColor.rgb, texColor.a);

    fragColor = vec4(finalColor, 1.0);
}
