#version 330 compatibility
#include "/lib/common.glsl"
#include "/lib/settings.glsl"

uniform sampler2D depthtex0;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex6;

uniform ivec2 eyeBrightnessSmooth;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);

    float depth = texture(depthtex0, texcoord).r;

	vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
	vec3 pos = screenToView(vec3(texcoord.xy, depth));

	vec3 fogcolor = calcSkyColor(normalize(pos));
	float fogdensity = 1.0;
	bool doFog = false;

	if ((depth < 1)){
		color.rgb = BSC(color.rgb, 1.0, 1.1, 1.0);
	}

	float renderdist;

	#if RENDER_DISTANCE == 1
		renderdist = 0.1;
	#elif RENDER_DISTANCE == 2
		renderdist = 0.175;
	#elif RENDER_DISTANCE == 3
		renderdist = 0.4;
	#elif RENDER_DISTANCE == 4
		renderdist = 0.6;
	#endif

	if (texture(colortex3, texcoord) == vec4(1)){
		renderdist *= 0.5;
	}

	#ifndef DISTANT_HORIZONS
	if ((depth < 1)){
		doFog = true;
	}
	#else
		doFog = false;
	#endif

	if (isEyeInWater == 1){
		fogcolor = vec3(0.05,0.05,0.35)*0.6;
		fogdensity = 0.15;
		renderdist = 8;
		doFog = true;
	}

	renderdist /= RENDER_DISTANCE_MULT;

	// Fog color follows the sky, so underground it would stay bright and wash out caves.
	// Fade it down to the terrain's ambient floor as the camera loses sky exposure.
	// Overworld-style dimensions only, and not underwater (keeps the water fog as is).
	float fogLight = 1.0;
	if (isEyeInWater == 0 && logicalHeightLimit == 384){
		float skyExposure = clamp(float(eyeBrightnessSmooth.y) / 240.0, 0.0, 1.0);
		fogLight = mix(MIN_LIGHT, 1.0, skyExposure);
	}

	float dist = (length(viewPos) / (64/fogdensity))*4*renderdist;

	#if RENDER_DISTANCE == 0
		dist = length(viewPos) / far;
	#endif

	#if RENDER_DISTANCE != 5
		#if RENDER_DISTANCE == 1 || RENDER_DISTANCE == 2
			if (doFog){
				float fogFactor = exp(-4*fogdensity * (1.0 - dist));
				color.rgb = mix(color.rgb, fogcolor * fogLight, clamp(fogFactor, 0.0, 1.0));
			}
		#elif RENDER_DISTANCE == 0
			if (far > 80){
				if (doFog){
					float fogFactor = exp(-4*fogdensity * (1.0 - dist));
					color.rgb = mix(color.rgb, fogcolor * fogLight, clamp(fogFactor, 0.0, 1.0));
				}
			}else{
				fogcolor = alphaFogColor;
				fogcolor = BSC(fogcolor, clamp(getLuminance(skyColor)*1.5, 0.0, 1.0), 1.0, 1.0);
				fogdensity = 0.9;
				if (isEyeInWater == 1){
					fogcolor = vec3(0.05,0.05,0.35)*0.6;
					fogdensity *= 0.1;
				}
				float fogFactor = exp(-4*fogdensity * (1.0 - dist));
				color.rgb = mix(color.rgb, fogcolor * fogLight, clamp(fogFactor, 0.0, 1.0));
			}
		#else
			fogcolor = alphaFogColor;
			fogcolor = BSC(fogcolor, clamp(getLuminance(skyColor)*1.5, 0.0, 1.0), 1.0, 1.0);
			fogdensity = 0.9;
			if (isEyeInWater == 1){
				fogcolor = vec3(0.05,0.05,0.35)*0.6;
				fogdensity *= 0.1;
			}
			float fogFactor = exp(-4*fogdensity * (1.0 - dist));
			color.rgb = mix(color.rgb, fogcolor * fogLight, clamp(fogFactor, 0.0, 1.0));
		#endif
	#endif

	// Rain/snow is rendered into colortex4 by gbuffers_weather (premultiplied alpha)
	// and layered on here, after fog, so it is never fogged by the terrain behind it.
	vec4 weather = texture(colortex4, texcoord);
	color.rgb = color.rgb * (1.0 - weather.a) + weather.rgb;

	color.rgb = BSC(color.rgb, BRIGHTNESS, SATURATION, CONTRAST);

	#ifdef WATERMARK
		ivec2 coord = ivec2(texcoord*vec2(viewWidth, viewHeight))/ivec2(WATERMARK_SCALE);
		coord.y = int(viewHeight/(WATERMARK_SCALE+0.005)) - coord.y;
		vec4 watermark = texelFetch(colortex6, coord, 0);
		color.rgb = mix(color.rgb, watermark.rgb, watermark.a);
	#endif
}