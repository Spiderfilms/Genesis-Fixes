#version 330 compatibility
#include "/lib/common.glsl"
#include "/lib/settings.glsl"
#include "/lib/light.glsl"

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D lightmap;
uniform sampler2D gtexture;
in vec3 normal;

uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

flat in int isWater;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	float brightness = 6;
	#if PRESET == 1
		brightness = 6;
	#endif
	if (bool(isWater)){
		vec4 waterColor = vec4(vec3(0,0,1), 1);
		waterColor.rgb = BSC(waterColor.rgb, brightness, 0.2, 1.0);
		color = texture(gtexture, texcoord) * waterColor;
		color.a = WATER_TRANSPARENCY;
		color.rgb = BSC(color.rgb, WATER_BRIGHTNESS, WATER_SATURATION, WATER_CONTRAST);
	}else{
		color = texture(gtexture, texcoord) * glcolor;
	}

	if (color.a < alphaTestRef) {
		discard;
	}

	// Lighting is applied here, to the translucent layer only. It used to be applied to the
	// whole blended pixel in composite.fsh, which meant guessing where translucent surfaces were
	// drawn, and left anything blended over water (like rain ripples) with unlit water showing.
	vec3 enc = normal * 0.5 + 0.5;
	float mult = enc.r * (1.0 - enc.r) * dot(enc, vec3(0.0, 1.0, 0.0));
	mult = clamp(mult * 4.0 + 0.25, 0.55, 1.0);

	vec3 light = legacyLight(texture(lightmap, lmcoord).rgb);
	color.rgb *= mult * BSC(light, 1.0, 0.0, 1.0);
}
