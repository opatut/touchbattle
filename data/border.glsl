extern vec2 size;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // float f = 0.0;
    vec4 col = Texel(texture, texture_coords);
    col *= color;

    const int r = 1;
    float d = 0.0;
    for(int x = -r; x <= r; x+=r) {
        for(int y = -r; y <= r; y+=r) {
            d += Texel(texture, texture_coords + vec2(x, y) / size * 0.4).a;
        }
    }
    d /= 9.0;
    if(d < 1.0) {
        col.rgb = mix(col.rgb, vec3(0, 0, 0), min(1.0, 3.0 - 3.0 * d));
    }

    col.rgb *= 1.0 - 2.0 * texture_coords.y;

    return col;
}