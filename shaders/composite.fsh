#version 330 compatibility

uniform sampler2D colortex0;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

// Pass-through. Water and other translucent surfaces are lit in their own passes now.
void main() {
	color = texture(colortex0, texcoord);
}
