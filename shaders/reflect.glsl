#define PI 3.1415

uniform float num_angles = 1;

uniform float offset = 0.0;
uniform float angle = 0.0;

uniform float zoom = 1.0;

uniform float color_phase = 0.0;
uniform float hue_phase = 0.0;
uniform float color_rate = 1.0;
uniform float mirror_level = 1.0;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
{
    vec4 pixel = vec4(0);
    for (float x=0; x<num_angles; ++x) {
        float rotation = x * PI * 2.0 / num_angles;
        float a = sin(rotation), b = cos(rotation);

        vec2 t;
        t = (tc - 0.5) / zoom;
        t = vec2(t.x*b - t.y*a + angle,
                 t.x*a + t.y*b + offset);
        t = mod(t + 0.5, 1.0);
        pixel += Texel(tex, t) / num_angles / 2.0;

        t = (tc - 0.5) / zoom;
        t = vec2(t.y*a - t.x*b + angle,
                 t.x*a + t.y*b + offset);
        t = mod(t + 0.5, 1.0);
        pixel += Texel(tex, t) / num_angles / 2.0 * mirror_level;
    }
    pixel = (pixel - 0.5) * color_rate + color_phase;
    float ph = hue_phase;
    float PHI = 1.61803;
    vec4 hue_offsets = vec4(ph/PHI, ph, ph*PHI, 0);
    vec4 px = pixel * PI + hue_offsets;
    pixel = (sin(px)*0.5 + pow(sin(px), vec4(3.0))*0.5) / 2.0 + 0.5;
    return vec4(pixel.rgb, color.a);
}
