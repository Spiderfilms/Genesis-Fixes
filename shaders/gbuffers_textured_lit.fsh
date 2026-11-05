#version 330 compatibility
#include "/lib/common.glsl"
#include "/lib/settings.glsl"
#include "/lib/light.glsl"

uniform sampler2D gtexture;
uniform sampler2D lightmap;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

// Used for particles, which are drawn after the deferred pass, so they light themselves.
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	if (color.a < alphaTestRef) {
		discard;
	}

	// Same brightness curve the terrain uses, reduced to neutral gray like
	// deferred.fsh does, applied once, here.
	vec3 l = legacyLight(texture(lightmap, lmcoord).rgb);
	color.rgb *= BSC(l, 1.0, 0.0, 1.0);
}
