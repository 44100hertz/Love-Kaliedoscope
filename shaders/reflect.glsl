#define PI 3.1415

uniform float num_angles = 1;

uniform float offset = 0.0;
uniform float angle = 0.0;

uniform float zoom = 1.0;

uniform float color_phase = 0.0;
uniform float color_period = 1.0;
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
    pixel = (pixel - 0.5) * color_period + 0.5 + color_phase;
    pixel = cos(pixel * PI + PI) / 2.0 + 0.5;
    return vec4(pixel.rgb, color.a);
}
