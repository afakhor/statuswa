#version 460 core

#include <flutter/runtime_effect.glsl>

uniform vec2 uResolution;  // Ukuran Canvas (width, height)
uniform float uTime;       // Waktu untuk rotasi otomatis
uniform sampler2D uTexture;// Gambar Tekstur (teks & ranting)

out vec4 fragColor;

const float PI = 3.14159265359;

void main() {
    // 1. Normalisasi koordinat layar (-1.0 sampai 1.0)
    vec2 st = (FragCoord().xy - 0.5 * uResolution) / min(uResolution.x, uResolution.y);

    // 2. Tentukan radius bola 3D
    float radius = 0.4;
    float dist = length(st);

    // Jika di luar lingkaran bola, buat background transparan/gelap
    if (dist > radius) {
        fragColor = vec4(0.0, 0.0, 0.0, 0.0);
        return;
    }

    // 3. Hitung koordinat Normal Z (Permukaan 3D Bola)
    float z = sqrt(radius * radius - dist * dist);
    vec3 normal = normalize(vec3(st.x, st.y, z));

    // 4. Konversi Normal 3D ke Koordinat UV (Equirectangular Projection)
    // Rotasi bola seiring waktu (uTime)
    float lon = atan(normal.z, normal.x) + uTime * 0.5;
    float lat = asin(normal.y);

    vec2 uv = vec2(lon / (2.0 * PI) + 0.5, lat / PI + 0.5);

    // 5. Sample warna dari Gambar Tekstur
    vec4 texColor = texture(uTexture, uv);

    // 6. Pencahayaan Emas 3D (Phong Reflection Model)
    vec3 lightDir = normalize(vec3(-0.5, 0.8, 1.0)); // Arah Cahaya Utama
    float diff = max(dot(normal, lightDir), 0.0);    // Diffuse light

    // Specular Highlight (Kilauan emas mengilap)
    vec3 viewDir = vec3(0.0, 0.0, 1.0);
    vec3 reflectDir = reflect(-lightDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);

    // Warna Dasar Emas (Gold Color Base)
    vec3 goldBase = vec3(1.0, 0.84, 0.0);
    vec3 goldDark = vec3(0.4, 0.25, 0.0);

    // Gabungkan Tekstur dengan Efek Emas & Pencahayaan
    vec3 baseColor = mix(goldBase, texColor.rgb, texColor.a);
    vec3 finalColor = goldDark * (1.0 - diff) + baseColor * diff + vec3(1.0) * spec * 0.8;

    fragColor = vec4(finalColor, 1.0);
}
