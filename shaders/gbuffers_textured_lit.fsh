#version 330 compatibility
#include "/lib/common.glsl"

uniform sampler2D gtexture;
uniform sampler2D lightmap;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

// Used for particles. They are drawn after the deferred pass and after the
// depthtex1 snapshot, so composite.fsh would otherwise treat them like water
// and light them a second time using the terrain behind them.
/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 light;
layout(location = 2) out vec4 encodedNormal;

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	if (color.a < alphaTestRef) {
		discard;
	}

	// Same brightness curve and ambient floor the terrain uses (gbuffer/common.glsl),
	// reduced to neutral gray like deferred.fsh does, applied once, here.
	vec3 l = texture(lightmap, lmcoord).rgb;
	if (l.r < 0.985) {
		l = pow(l, vec3(3));
	} else {
		l = vec3(1);
	}
	float ambient = (logicalHeightLimit == 384) ? 0.045 : 0.25;
	l = clamp(l, ambient, 1.0);
	color.rgb *= BSC(l, 1.0, 0.0, 1.0);

	// Neutral values (full light, upward-facing normal) so composite.fsh
	// leaves particle pixels unchanged.
	light = vec4(1.0);
	encodedNormal = vec4(0.5, 1.0, 0.5, 1.0);
}
