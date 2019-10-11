module magicalrainbows.properties;

import magicalrainbows.utils;

real relativeLuminosity(Colour)(const Colour colour) if(isColourFormat!Colour) {
	return 0.2126 * colour.redFP.toLinearRGB +
		0.7152 * colour.greenFP.toLinearRGB +
		0.0722 * colour.blueFP.toLinearRGB;
}

@safe pure unittest {
	import magicalrainbows.formats : BGR555, RGB888;
	import std.math : approxEqual;
	assert(RGB888(0, 0, 0).relativeLuminosity.approxEqual(0.0));
	assert(RGB888(255, 255, 255).relativeLuminosity.approxEqual(1.0));
	assert(RGB888(250, 112, 20).relativeLuminosity.approxEqual(0.3196));
	assert(BGR555(0, 16, 31).relativeLuminosity.approxEqual(0.23618));
}

real contrast(Colour1, Colour2)(const Colour1 colour1, const Colour2 colour2) if (isColourFormat!Colour1 && isColourFormat!Colour2) {
	import std.algorithm.comparison : max, min;
	const L1 = colour1.relativeLuminosity;
	const L2 = colour2.relativeLuminosity;
	return (max(L1, L2) + 0.05) / (min(L1, L2) + 0.05);
}

@safe pure unittest {
	import magicalrainbows.formats : RGB888;
	import std.math : approxEqual;
	assert(contrast(RGB888(0, 0, 0), RGB888(0, 0, 0)).approxEqual(1.0));
	assert(contrast(RGB888(0, 0, 0), RGB888(255, 255, 255)).approxEqual(21.0));
	assert(contrast(RGB888(255, 255, 255), RGB888(0, 0, 0)).approxEqual(21.0));
	assert(contrast(RGB888(255, 255, 255), RGB888(250, 112, 20)).approxEqual(2.8407));
}
