uniform float brightness = 0.0;
uniform float contrast = 1.0;
uniform float offset = 0.0;

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc)
{
    tc = mod(tc + offset, 1.0);
    vec4 pixel = Texel(tex, tc);
//    vec4 spixel = vec4(sin(contrast * pixel.rgb - 3.1415/2.0)/2.0 + 0.5, pixel.a);
//    vec4 spixel = vec4(sin(3.14/2.0 + contrast*pixel.rgb*2.5)/2.0 + 0.5, pixel.a);
    float alpha = pixel.a;
    pixel = (pixel - 0.5) * contrast + 0.5 + brightness;
    pixel.a = alpha;
    return pixel * color;
}
