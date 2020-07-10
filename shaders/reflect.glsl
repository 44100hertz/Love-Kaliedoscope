uniform float num_angles = 1;

uniform float offset = 0.0;
uniform float zoom = 1.0;

uniform float brightness = 0.0;
uniform float contrast = 1.0;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
{
    vec4 pixel = vec4(0);
    for (float x=0; x<num_angles; ++x) {
        float rotation = x * 3.1415 * 2.0 / num_angles;
        float a = sin(rotation), b = cos(rotation);

        vec2 t;
        t = (tc - 0.5) / zoom;
        t = vec2(t.x*b - t.y*a + offset,
                 t.x*a + t.y*b + offset/2.0);
        t = mod(t + 0.5, 1.0);
        pixel += Texel(tex, t) / num_angles / 2.0;

        t = (tc - 0.5) / zoom;
        t = vec2(t.y*a - t.x*b + offset,
                 t.x*a + t.y*b + offset/2.0);
        t = mod(t + 0.5, 1.0);
        pixel += Texel(tex, t) / num_angles / 2.0;
    }
    pixel = (pixel - 0.5) * contrast + 0.5 + brightness;
    return vec4(pixel.rgb, color.a);
}
