///
module pixelmancy.colours.properties;

import pixelmancy.colours.utils;

Precision relativeLuminosity(Precision = double, Colour)(const Colour colour) if(isRGBColourFormat!Colour) {
	const linear = colour.asLinearRGB!Precision;
	return 0.2126 * linear.red +
		0.7152 * linear.green +
		0.0722 * linear.blue;
}
///
@safe pure unittest {
	import pixelmancy.colours.formats : BGR555, RGB24;
	import std.math : isClose;
	assert(RGB24(0, 0, 0).relativeLuminosity.isClose(0.0));
	assert(RGB24(255, 255, 255).relativeLuminosity.isClose(1.0));
	assert(RGB24(250, 112, 20).relativeLuminosity.isClose(0.3196284130));
	assert(BGR555(0, 16, 31).relativeLuminosity.isClose(0.2361773154));
}

Precision contrast(Precision = double, Colour1, Colour2)(const Colour1 colour1, const Colour2 colour2) if (isRGBColourFormat!Colour1 && isRGBColourFormat!Colour2) {
	import std.algorithm.comparison : max, min;
	const L1 = colour1.relativeLuminosity!Precision;
	const L2 = colour2.relativeLuminosity!Precision;
	return (max(L1, L2) + 0.05) / (min(L1, L2) + 0.05);
}
///
@safe pure unittest {
	import pixelmancy.colours.formats : RGB24;
	import std.math : isClose;
	assert(contrast(RGB24(0, 0, 0), RGB24(0, 0, 0)).isClose(1.0));
	assert(contrast(RGB24(0, 0, 0), RGB24(255, 255, 255)).isClose(21.0));
	assert(contrast(RGB24(255, 255, 255), RGB24(0, 0, 0)).isClose(21.0));
	assert(contrast(RGB24(255, 255, 255), RGB24(250, 112, 20)).isClose(2.8406907130));
}

Colour complementary(Colour)(const Colour colour) if (isRGBColourFormat!Colour) {
	Colour result;
	static if (hasRed!Colour) {
		result.red = colour.red^maxRed!Colour;
	}
	static if (hasGreen!Colour) {
		result.green = colour.green^maxGreen!Colour;
	}
	static if (hasBlue!Colour) {
		result.blue = colour.blue^maxBlue!Colour;
	}
	return result;
}
///
@safe pure unittest {
	import pixelmancy.colours.formats : RGB24;
	assert(RGB24(0, 0, 0).complementary == RGB24(255, 255, 255));
	assert(RGB24(255, 255, 255).complementary == RGB24(0, 0, 0));
	assert(RGB24(0, 255, 255).complementary == RGB24(255, 0, 0));
	assert(RGB24(0, 128, 0).complementary == RGB24(255, 127, 255));
}
