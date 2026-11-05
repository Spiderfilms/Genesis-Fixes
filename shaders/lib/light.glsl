// Legacy-style brightness for a lightmap sample.
// Needs /lib/common.glsl (logicalHeightLimit) and /lib/settings.glsl (MIN_LIGHT, LIGHT_CURVE)
// to be included first.
//
// Overworld-style dimensions: MIN_LIGHT is the brightness of completely dark areas, and
// LIGHT_CURVE sets how quickly dim areas fall off (higher = darker). The curve is lifted by
// MIN_LIGHT instead of being clamped to it, so dim areas keep a visible light gradient.
// Nether, End and other dimensions keep the original curve and floor.
vec3 legacyLight(vec3 lm) {
	if (logicalHeightLimit == 384) {
		vec3 l = (lm.r < 0.985) ? MIN_LIGHT + (1.0 - MIN_LIGHT) * pow(lm, vec3(LIGHT_CURVE)) : vec3(1.0);
		return clamp(l, MIN_LIGHT, 1.0);
	}
	vec3 l = (lm.r < 0.985) ? pow(lm, vec3(3.0)) : vec3(1.0);
	return clamp(l, 0.25, 1.0);
}
