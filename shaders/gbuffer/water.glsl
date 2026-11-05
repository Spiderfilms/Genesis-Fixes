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

/* RENDERTARGETS: 0,1,2,5 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 light;
layout(location = 2) out vec4 encodedNormal;
layout(location = 3) out vec4 translucentMask;

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

	vec2 lmc = lmcoord;
	light = texture(lightmap, lmc);

	light.rgb = legacyLight(light.rgb);
	if (color.a < alphaTestRef) {
		discard;
	}

	encodedNormal = vec4(normal * 0.5 + 0.5, 1.0);

	// Marks pixels drawn by this pass so composite.fsh doesn't have to guess
	// from depth (which breaks down where water meets terrain).
	translucentMask = vec4(1.0);
}
