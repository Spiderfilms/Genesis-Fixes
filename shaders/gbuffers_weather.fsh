#version 330 compatibility
#include "/lib/common.glsl"

uniform sampler2D gtexture;
uniform sampler2D lightmap;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

// Rain and snow are written to their own buffer instead of colortex0.
// final.fsh layers colortex4 over the scene after fog is applied.
/* RENDERTARGETS: 4 */
layout(location = 0) out vec4 weather;

void main() {
	vec4 c = texture(gtexture, texcoord) * glcolor;
	if (c.a < alphaTestRef) {
		discard;
	}

	// Same brightness curve and ambient floor the terrain uses (gbuffer/common.glsl),
	// reduced to neutral gray like deferred.fsh does, so the modern tinted
	// lightmap doesn't color the weather.
	vec3 light = texture(lightmap, lmcoord).rgb;
	if (light.r < 0.985) {
		light = pow(light, vec3(3));
	} else {
		light = vec3(1);
	}
	float ambient = (logicalHeightLimit == 384) ? 0.045 : 0.25;
	light = clamp(light, ambient, 1.0);

	c.rgb *= BSC(light, 1.0, 0.0, 1.0);
	weather = c;
}
