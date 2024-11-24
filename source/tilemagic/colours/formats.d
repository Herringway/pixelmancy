module tilemagic.colours.formats;

import tilemagic.colours.utils;

import std.algorithm;
import std.bitmanip;
import std.conv;
import std.range;


struct BGR555 { //XBBBBBGG GGGRRRRR
	enum redSize = 5;
	enum greenSize = 5;
	enum blueSize = 5;
	enum alphaSize = 0;
	mixin colourConstructors;
	mixin(bitfields!(
		uint, "red", redSize,
		uint, "green", greenSize,
		uint, "blue", blueSize,
		bool, "padding", 1));
}
static assert(BGR555.sizeof == 2);

@safe pure unittest {
	with(BGR555(AnalogRGBD(1.0, 0.5, 0.0))) {
		assert(red == 31);
		assert(green == 15);
		assert(blue == 0);
	}
}

struct RGB555 { //XRRRRRGG GGGBBBBB
	enum redSize = 5;
	enum greenSize = 5;
	enum blueSize = 5;
	enum alphaSize = 0;
	mixin colourConstructors;
	mixin(bitfields!(
		uint, "blue", blueSize,
		uint, "green", greenSize,
		uint, "red", redSize,
		bool, "padding", 1));
}
static assert(RGB555.sizeof == 2);

struct BGR565 { //BBBBBGGG GGGRRRRR
	enum redSize = 5;
	enum greenSize = 6;
	enum blueSize = 5;
	enum alphaSize = 0;
	mixin colourConstructors;
	mixin(bitfields!(
		uint, "red", redSize,
		uint, "green", greenSize,
		uint, "blue", blueSize));
}
static assert(BGR565.sizeof == 2);

struct BGR222 { //00BBGGRR
	enum redSize = 2;
	enum greenSize = 2;
	enum blueSize = 2;
	enum alphaSize = 0;
	mixin colourConstructors;
	mixin(bitfields!(
		uint, "red", redSize,
		uint, "green", greenSize,
		uint, "blue", blueSize,
		ubyte, "padding", 2));
}
static assert(BGR222.sizeof == 1);
struct BGR333MD { //0000BBB0 GGG0RRR0
	enum redSize = 3;
	enum greenSize = 3;
	enum blueSize = 3;
	enum alphaSize = 0;
	mixin colourConstructors;
	mixin(bitfields!(
		ubyte, "padding0", 1,
		uint, "red", redSize,
		ubyte, "padding1", 1,
		uint, "green", greenSize,
		ubyte, "padding2", 1,
		uint, "blue", blueSize,
		ubyte, "padding3", 4));
}
static assert(BGR333MD.sizeof == 2);

struct RGB888 { //RRRRRRRR GGGGGGGG BBBBBBBB
	enum redSize = 8;
	enum greenSize = 8;
	enum blueSize = 8;
	enum alphaSize = 0;
	mixin colourConstructors;
	ubyte red;
	ubyte green;
	ubyte blue;
}
static assert(RGB888.sizeof == 3);

struct BGR888 { //BBBBBBBB GGGGGGGG RRRRRRRR
	enum redSize = 8;
	enum greenSize = 8;
	enum blueSize = 8;
	enum alphaSize = 0;
	mixin colourConstructors;
	ubyte blue;
	ubyte green;
	ubyte red;
}
static assert(BGR888.sizeof == 3);

struct RGBA8888 { //RRRRRRRR GGGGGGGG BBBBBBBB AAAAAAAA
	enum redSize = 8;
	enum greenSize = 8;
	enum blueSize = 8;
	enum alphaSize = 8;
	mixin colourConstructors;
	ubyte red;
	ubyte green;
	ubyte blue;
	ubyte alpha;
}
static assert(RGBA8888.sizeof == 4);
@safe pure unittest {
	with(RGBA8888(AnalogRGBAD(1.0, 0.5, 0.0, 0.0))) {
		assert(red == 255);
		assert(green == 127);
		assert(blue == 0);
		assert(alpha == 0);
	}
	with(RGBA8888(255, 128, 0, 0)) {
		assert(red == 255);
		assert(green == 128);
		assert(blue == 0);
		assert(alpha == 0);
	}
}
struct BGRA8888 { // BBBBBBBB GGGGGGGG RRRRRRRR AAAAAAAA
	enum redSize = 8;
	enum greenSize = 8;
	enum blueSize = 8;
	enum alphaSize = 8;
	mixin colourConstructors;
	ubyte blue;
	ubyte green;
	ubyte red;
	ubyte alpha;
}

static assert(BGRA8888.sizeof == 4);

alias AnalogRGBF = AnalogRGB!float;
alias AnalogRGBD = AnalogRGB!double;
alias AnalogRGBR = AnalogRGB!real;

struct AnalogRGB(Precision) {
	Precision red;
	Precision green;
	Precision blue;
}

alias AnalogRGBAF = AnalogRGBA!float;
alias AnalogRGBAD = AnalogRGBA!double;
alias AnalogRGBAR = AnalogRGBA!real;
struct AnalogRGBA(Precision) {
	Precision red;
	Precision green;
	Precision blue;
	Precision alpha;
}

alias HSVF = HSV!float;
alias HSVD = HSV!double;
alias HSVR = HSV!real;
struct HSV(Precision) {
	Precision hue;
	Precision saturation;
	Precision value;
	@safe invariant {
		assert(hue >= 0);
		assert(saturation >= 0);
		assert(value >= 0);
		assert(hue <= 1.0);
		assert(saturation <= 1.0);
		assert(value <= 1.0);
	}
}
struct HSVA(Precision) {
	Precision hue;
	Precision saturation;
	Precision value;
	Precision alpha;
	@safe invariant {
		assert(hue >= 0);
		assert(saturation >= 0);
		assert(value >= 0);
		assert(alpha >= 0);
		assert(hue <= 1.0);
		assert(saturation <= 1.0);
		assert(value <= 1.0);
		assert(alpha <= 1.0);
	}
}

///
HSV!Precision toHSV(Precision = double, Format)(Format input) if (isColourFormat!Format) {
	import std.algorithm.comparison : max, min;
	import std.math : isClose;
	HSV!Precision result;
	const red = input.redFP;
	const green = input.greenFP;
	const blue = input.blueFP;
	const minimum = min(red, green, blue);
	const maximum = max(red, green, blue);
	const delta = maximum - minimum;

	result.value = maximum;
	if (delta < 0.00001)
	{
		result.saturation = 0;
		result.hue = 0;
		return result;
	}
	if (maximum > 0.0) {
		result.saturation = delta / maximum;
	}

	if (isClose(red, maximum)) {
		result.hue = (green - blue) / delta; //yellow, magenta
	} else if (isClose(green, maximum)) {
		result.hue = 2.0 + (blue - red) / delta; //cyan, yellow
	} else {
		result.hue = 4.0 + (red - green) / delta; //magenta, cyan
	}

	result.hue /= 6.0;
	if (result.hue < 0.0) {
		result.hue += 1.0;
	}
	assert(result.hue >= 0.0);

	return result;
}

///
@safe unittest {
	import std.math : isClose;
	with(RGB888(0, 0, 0).toHSV) {
		assert(hue == 0);
		assert(saturation == 0);
		assert(value == 0);
	}
	with(RGB888(0, 128, 192).toHSV) {
		assert(hue.isClose(0.5555555555));
		assert(saturation.isClose(1.0));
		assert(value.isClose(0.7529411765));
	}
	with(RGB888(255, 255, 0).toHSV) {
		assert(hue.isClose(0.1666666667));
		assert(saturation.isClose(1.0));
		assert(value.isClose(1.0));
	}
	with(RGB888(255, 0, 0).toHSV) {
		assert(hue.isClose(0.0));
		assert(saturation.isClose(1.0));
		assert(value.isClose(1.0));
	}
	with(RGB888(255, 0, 255).toHSV) {
		assert(hue.isClose(0.8333333333));
		assert(saturation.isClose(1.0));
		assert(value.isClose(1.0));
	}
	with(RGB888(0, 255, 0).toHSV) {
		assert(hue.isClose(0.3333333333));
		assert(saturation.isClose(1.0));
		assert(value.isClose(1.0));
	}
	with(RGB888(0, 0, 255).toHSV) {
		assert(hue.isClose(0.6666666667));
		assert(saturation.isClose(1.0));
		assert(value.isClose(1.0));
	}
}

///
HSVA!Precision toHSVA(Precision = double, Format)(Format input) if (isColourFormat!Format) {
	const result = input.toHSV();
	static if (hasAlpha!Format) {
		return HSVA!Precision(result.hue, result.saturation, result.value, input.alphaFP);
	} else {
		return HSVA!Precision(result.hue, result.saturation, result.value, 1.0);
	}
}

///
@safe unittest {
	import std.math : isClose;
	with(RGB888(255, 0, 0).toHSVA) {
		assert(hue.isClose(0.0));
		assert(saturation.isClose(1.0));
		assert(value.isClose(1.0));
		assert(alpha.isClose(1.0));
	}
	with(RGBA8888(255, 0, 0, 255).toHSVA) {
		assert(hue.isClose(0.0));
		assert(saturation.isClose(1.0));
		assert(value.isClose(1.0));
		assert(alpha.isClose(1.0));
	}
	with(RGBA8888(255, 0, 0, 0).toHSVA) {
		assert(hue.isClose(0.0));
		assert(saturation.isClose(1.0));
		assert(value.isClose(1.0));
		assert(alpha.isClose(0.0));
	}
}

///
Format toRGB(Format = RGB888, Precision = double)(HSV!Precision input) @safe if (isColourFormat!Format) {
	static if (hasAlpha!Format) {
		alias AnalogRGBT = AnalogRGBA!Precision;
	} else {
		alias AnalogRGBT = AnalogRGB!Precision;
	}

	if(input.saturation <= 0.0) {
		static if (hasAlpha!Format) {
			return Format(AnalogRGBT(input.value, input.value, input.value, 1.0));
		} else {
			return Format(AnalogRGBT(input.value, input.value, input.value));
		}
	}
	Precision hh = input.hue * 6.0;
	if(hh > 6.0) {
		hh	 = 0.0;
	}
	long i = cast(long)hh;
	Precision ff = hh - i;
	Precision p = input.value * (1.0 - input.saturation);
	Precision q = input.value * (1.0 - (input.saturation * ff));
	Precision t = input.value * (1.0 - (input.saturation * (1.0 - ff)));

	assert(p <= 1.0);
	assert(q <= 1.0);
	assert(t <= 1.0);
	AnalogRGBT rgb;
	switch(i) {
		case 0:
			rgb = AnalogRGBT(input.value, t, p);
			break;
		case 1:
			rgb = AnalogRGBT(q, input.value, p);
			break;
		case 2:
			rgb = AnalogRGBT(p, input.value, t);
			break;
		case 3:
			rgb = AnalogRGBT(p, q, input.value);
			break;
		case 4:
			rgb = AnalogRGBT(t, p, input.value);
			break;
		case 5:
		default:
			rgb = AnalogRGBT(input.value, p, q);
			break;
	}
	static if (hasAlpha!Format) {
		rgb.alpha = 1.0;
	}
	return Format(rgb);
}
///
@safe unittest {
	with(HSVD(0, 0, 0).toRGB!RGB888) {
		assert(red == 0);
		assert(green == 0);
		assert(blue == 0);
	}
	with(HSVD(0, 0, 0.5).toRGB!RGB888) {
		assert(red == 127);
		assert(green == 127);
		assert(blue == 127);
	}
	with(HSVD(0.5555555, 1.0, 0.752941).toRGB!RGB888) {
		assert(red == 0);
		assert(green == 128);
		assert(blue == 191);
	}
	with(HSVD(0.166666667, 1.0, 1.0).toRGB!RGB888) {
		assert(red == 254);
		assert(green == 255);
		assert(blue == 0);
	}
	with(HSVD(0.0, 1.0, 1.0).toRGB!RGB888) {
		assert(red == 255);
		assert(green == 0);
		assert(blue == 0);
	}
	with(HSVD(0.83333333, 1.0, 1.0).toRGB!RGB888) {
		assert(red == 254);
		assert(green == 0);
		assert(blue == 255);
	}
	with(HSVD(0.33333333, 1.0, 1.0).toRGB!RGB888) {
		assert(red == 0);
		assert(green == 255);
		assert(blue == 0);
	}
	with(HSVD(0.66666667, 1.0, 1.0).toRGB!RGB888) {
		assert(red == 0);
		assert(green == 0);
		assert(blue == 255);
	}
	with(HSVD(0.41666667, 1.0, 1.0).toRGB!RGB888) {
		assert(red == 0);
		assert(green == 255);
		assert(blue == 127);
	}
	with(HSVD(0.91666667, 1.0, 1.0).toRGB!RGB888) {
		assert(red == 255);
		assert(green == 0);
		assert(blue == 127);
	}
}
///
Format toRGB(Format = RGB888, Precision = double)(HSVA!Precision input) @safe if (isColourFormat!Format) {
	Format result = HSV!Precision(input.hue, input.saturation, input.value).toRGB!Format();
	static if (hasAlpha!Format) {
		result.alphaFP = input.alpha;
	}
	return result;
}
///
@safe unittest {
	with(HSVA!double(0, 0, 0.5, 0.0).toRGB!RGBA8888) {
		assert(red == 127);
		assert(green == 127);
		assert(blue == 127);
		assert(alpha == 0);
	}
	with(HSVA!double(0, 0, 0.5, 1.0).toRGB!RGBA8888) {
		assert(red == 127);
		assert(green == 127);
		assert(blue == 127);
		assert(alpha == 255);
	}
	with(HSVA!double(0, 0, 0.5, 1.0).toRGB!RGB888) {
		assert(red == 127);
		assert(green == 127);
		assert(blue == 127);
	}
}

struct ColourPair(Foreground, Background) if (isColourFormat!Foreground && isColourFormat!Background) {
	Foreground foreground;
	Background background;
	Precision contrast(Precision = double)() const @safe pure {
		import tilemagic.colours.properties : contrast;
		return contrast!Precision(foreground, background);
	}
	bool meetsWCAGAACriteria() const @safe pure {
		return contrast >= 4.5;
	}
	bool meetsWCAGAAACriteria() const @safe pure {
		return contrast >= 7.0;
	}
}

ColourPair!(Foreground, Background) colourPair(Foreground, Background)(Foreground foreground, Background background) if (isColourFormat!Foreground && isColourFormat!Background) {
	return ColourPair!(Foreground, Background)(foreground, background);
}
///
@safe pure unittest {
	import std.math : isClose;
	with(colourPair(RGB888(0, 0, 0), RGB888(255, 255, 255))) {
		assert(contrast.isClose(21.0));
		assert(meetsWCAGAACriteria);
		assert(meetsWCAGAAACriteria);
	}
	with(colourPair(RGB888(255, 255, 255), RGB888(255, 255, 255))) {
		assert(contrast.isClose(1.0));
		assert(!meetsWCAGAACriteria);
		assert(!meetsWCAGAAACriteria);
	}
	with(colourPair(RGB888(0, 128, 255), RGB888(0, 0, 0))) {
		assert(contrast.isClose(5.5316685936));
		assert(meetsWCAGAACriteria);
		assert(!meetsWCAGAAACriteria);
	}
	with(colourPair(BGR555(0, 16, 31), RGB888(0, 0, 0))) {
		assert(contrast.isClose(5.7235463090));
		assert(meetsWCAGAACriteria);
		assert(!meetsWCAGAAACriteria);
	}
}

Target convert(Target, Source)(Source from) if (isColourFormat!Source && isColourFormat!Target) {
	static if (is(Source : Target)) {
		return from;
	} else {
		Target output;
		static if (hasRed!Source && hasRed!Target) {
			output.red = colourConvert!(typeof(output.red), Target.redSize, Source.redSize)(from.red);
		}
		static if (hasGreen!Source && hasGreen!Target) {
			output.green = colourConvert!(typeof(output.green), Target.greenSize, Source.greenSize)(from.green);
		}
		static if (hasBlue!Source && hasBlue!Target) {
			output.blue = colourConvert!(typeof(output.blue), Target.blueSize, Source.blueSize)(from.blue);
		}
		static if (hasAlpha!Source && hasAlpha!Target) {
			output.alpha = colourConvert!(typeof(output.alpha), Target.alphaSize, Source.alphaSize)(from.alpha);
		} else static if (hasAlpha!Target) {
			output.alpha = output.alpha.max;
		}
		return output;
	}
}
///
@safe pure unittest {
	assert((const BGR555)(31,31,31).convert!BGR555 == BGR555(31, 31, 31));
	assert(BGR555(31,31,31).convert!RGB888 == RGB888(248, 248, 248));
	assert(BGR555(0, 0, 0).convert!RGB888 == RGB888(0, 0, 0));
	assert(RGB888(248, 248, 248).convert!BGR555 == BGR555(31,31,31));
	assert(RGB888(0, 0, 0).convert!BGR555 == BGR555(0, 0, 0));
}

Format fromHex(Format = RGB888)(const string colour) @safe pure if (isColourFormat!Format) {
	Format output;
	string tmpStr = colour[];
	if (colour.empty) {
		throw new Exception("Cannot parse an empty string");
	}
	if (tmpStr.front == '#') {
		tmpStr.popFront();
	}
	enum alphaAdjustment = hasAlpha!Format ? 1 : 0;
	if (tmpStr.length == 3 + alphaAdjustment) {
		auto tmp = tmpStr[0].repeat(2);
		output.red = tmp.parse!ubyte(16);
		tmp = tmpStr[1].repeat(2);
		output.green = tmp.parse!ubyte(16);
		tmp = tmpStr[2].repeat(2);
		output.blue = tmp.parse!ubyte(16);
		static if (hasAlpha!Format) {
			tmp = tmpStr[3].repeat(2);
			output.alpha = tmp.parse!ubyte(16);
		}
	} else if (tmpStr.length == (3 + alphaAdjustment) * 2) {
		auto tmp = tmpStr[0..2];
		output.red = tmp.parse!ubyte(16);
		tmp = tmpStr[2..4];
		output.green = tmp.parse!ubyte(16);
		tmp = tmpStr[4..6];
		output.blue = tmp.parse!ubyte(16);
		static if (hasAlpha!Format) {
			tmp = tmpStr[6..8];
			output.alpha = tmp.parse!ubyte(16);
		}
	}
	return output;
}
///
@safe pure unittest {
	assert("#000000".fromHex == RGB888(0, 0, 0));
	assert("#FFFFFF".fromHex == RGB888(255, 255, 255));
	assert("FFFFFF".fromHex == RGB888(255, 255, 255));
	assert("#FFF".fromHex == RGB888(255, 255, 255));
	assert("#888".fromHex == RGB888(0x88, 0x88, 0x88));
	assert("888".fromHex == RGB888(0x88, 0x88, 0x88));
	assert("#FFFFFFFF".fromHex!RGBA8888 == RGBA8888(255, 255, 255, 255));
	assert("#FFFF".fromHex!RGBA8888 == RGBA8888(255, 255, 255, 255));
}

//TODO: can we express these with fractions instead?

//Assumptions:
// R,G,B,Y [0, 255]
// Pb,Pr [-127.5, 127.5]
enum YPbPrSDTVToRGBMatrix = [
	[1.0, 0.0, 1.402],
	[1.0, -0.344, -0.714],
	[1.0, 1.772, 0.0],
];
//Assumptions:
// R,G,B,Y [0, 255]
// Pb,Pr [-127.5, 127.5]
enum YPbPrHDTVToRGBMatrix = [
	[1.0, 0.0, 1.575],
	[1.0, -0.187, -0.468],
	[1.0, 1.856, 0.0],
];

//Assumptions:
// R,G,B,Y [0, 255]
// Pb,Pr [-127.5, 127.5]
enum RGBToYPbPrSDTVMatrix = [
	[0.299, 0.587, 0.114],
	[-0.169, -0.331, 0.5],
	[0.5, -0.419, -0.081],
];

//Assumptions:
// R,G,B,Y [0, 255]
// Pb,Pr [-127.5, 127.5]
enum RGBToYPbPrHDTVMatrix = [
	[0.213, 0.715, 0.072],
	[-0.115, -0.385, 0.5],
	[0.5, -0.454, -0.046],
];

struct YPbPr {
	double Y;
	double Pb;
	double Pr;
}

//Assumptions:
// R,G,B,Y [0, 1]
// U [-0.436, 0.436]
// V [-0.615, 0.615]
enum RGBToYUVMatrix = [
	[0.299, 0.587, 0.114],
	[-0.147, -0.289, 0.436],
	[0.615, -0.515, -0.100]
];

//Assumptions:
// R,G,B,Y [0, 1]
// U [-0.436, 0.436]
// V [-0.615, 0.615]
enum YUVToRGBMatrix = [
	[1.0, 0.0, 1.140],
	[1.0, -0.395, -0.581],
	[1.0, 2.032, 0.0],
];

struct YUV {
	double Y;
	double Cb;
	double Cr;
}

enum YCbCrSDTVVector = [[16], [128], [128]];
alias YCbCrHDTVVector = YCbCrSDTVVector;
enum YCbCrFullRangeVector = [[0], [128], [128]];

//Assumptions:
// R,G,B [0, 255]
// Y [16, 235]
// Cb,Cr [16, 240]
enum YCbCrSDTVToRGBMatrix = [
	[1.164, 0.0, 1.596],
	[1.164, -0.392, -0.813],
	[1.164, 2.017, 0.0],
];

//Assumptions:
// R,G,B [0, 255]
// Y [16, 235]
// Cb,Cr [16, 240]
enum YCbCrHDTVToRGBMatrix = [
	[1.164, 0.0, 1.793],
	[1.164, -0.213, -0.533],
	[1.164, 2.112, 0.0],
];

//Assumptions:
// R,G,B,Y,Cb,Cr [0, 255]
enum YCbCrFullRangeToRGBMatrix = [
	[1.0, 0.0, 1.4],
	[1.0, -0.343, -0.711],
	[1.0, 1.765, 0.0],
];

//Assumptions:
// R,G,B [0, 255]
// Y [16, 235]
// Cb,Cr [16, 240]
enum RGBToYCbCrSDTVMatrix = [
	[0.257, 0.504, 0.098],
	[-0.148, -0.291, 0.439],
	[0.439, -0.368, -0.071],
];

//Assumptions:
// R,G,B [0, 255]
// Y [16, 235]
// Cb,Cr [16, 240]
enum RGBToYCbCrHDTVMatrix = [
	[0.183, 0.614, 0.062],
	[-0.101, -0.339, 0.439],
	[0.439, -0.399, -0.040],
];

//Assumptions:
// R,G,B,Y,Cb,Cr [0, 255]
enum RGBToYCbCrFullRangeMatrix = [
	[0.299, 0.587, 0.114],
	[-0.169, -0.331, 0.500],
	[0.500, -0.419, -0.081],
];

struct YCbCr {
	double Y;
	double Cb;
	double Cr;
}
