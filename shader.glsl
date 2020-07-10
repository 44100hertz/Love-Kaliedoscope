uniform float brightness = 0.0;
uniform float contrast = 1.0;
uniform float offset = 0.0;
uniform float rotation = 0.0;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
{
    float a = sin(rotation), b = cos(rotation);
    tc = tc - 0.5;
    tc = vec2(tc.x*b - tc.y*a + offset,
              tc.x*a + tc.y*b);
    tc = mod(tc + 0.5, 1.0);
    vec4 pixel = Texel(tex, tc);
    pixel = (pixel - 0.5) * contrast + 0.5 + brightness;
    return vec4(pixel.rgb, color.a);
}
