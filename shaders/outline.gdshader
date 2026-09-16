shader_type spatial;
// The dark cartoon outline around the food, drawn as a second pass.
//
// It is the "inverted hull" trick every cel-shaded game uses: draw the object
// again, a little bigger, showing only its BACK faces in a flat dark colour. The
// real object covers the middle, so only a thin rim of the bigger copy is left
// peeking out around the edge — and that rim is the outline.
//
// The growth happens in camera space, so the line stays the same thickness on a
// flat plate that was stretched tall and on a round bun that was not.
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled;

uniform vec4 outline_color : source_color = vec4(0.16, 0.11, 0.08, 1.0);
// How far the hull grows, in metres at the camera's distance. Bigger = thicker.
uniform float thickness = 0.028;

void vertex() {
	vec4 view_pos = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 view_normal = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	view_pos.xyz += view_normal * thickness;
	POSITION = PROJECTION_MATRIX * view_pos;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
