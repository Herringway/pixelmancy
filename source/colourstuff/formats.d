module colourstuff.formats;

import colourstuff.utils;

import std.algorithm;
import std.bitmanip;
import std.conv;
import std.range;

mixin template colourConstructors() {
	this(uint red, uint green, uint blue) pure @safe
		in(red < (1<<redSize), "Red value out of range")
		in(green < (1<<greenSize), "Green value out of range")
		in(blue < (1<<blueSize), "Blue value out of range")
	{
		this.red = cast(typeof(this.red))red;
		this.green = cast(typeof(this.green))green;
		this.blue = cast(typeof(this.blue))blue;
	}
	this(real red, real green, real blue) pure @safe
		in(red <= 1.0, "Red value out of range")
		in(red >= 0.0, "Red value out of range")
		in(green <= 1.0, "Green value out of range")
		in(green >= 0.0, "Green value out of range")
		in(blue <= 1.0, "Blue value out of range")
		in(blue >= 0.0, "Blue value out of range")
	{
		this.red = cast(typeof(this.red))(red * maxRed!(typeof(this)));
		this.green = cast(typeof(this.green))(green * maxGreen!(typeof(this)));
		this.blue = cast(typeof(this.blue))(blue * maxBlue!(typeof(this)));
	}
	static if (alphaSize > 0) {
		this(uint red, uint green, uint blue, uint alpha) pure @safe
			in(red < (1<<redSize), "Red value out of range")
			in(green < (1<<greenSize), "Green value out of range")
			in(blue < (1<<blueSize), "Blue value out of range")
			in(alpha < (1<<alphaSize), "Alpha value out of range")
		{
			this.red = cast(typeof(this.red))red;
			this.green = cast(typeof(this.green))green;
			this.blue = cast(typeof(this.blue))blue;
			this.alpha = cast(typeof(this.alpha))alpha;
		}
		this(real red, real green, real blue, real alpha) pure @safe
			in(red <= 1.0, "Red value out of range")
			in(red >= 0.0, "Red value out of range")
			in(green <= 1.0, "Green value out of range")
			in(green >= 0.0, "Green value out of range")
			in(blue <= 1.0, "Blue value out of range")
			in(blue >= 0.0, "Blue value out of range")
			in(alpha <= 1.0, "Blue value out of range")
			in(alpha >= 0.0, "Blue value out of range")
		{
			this.red = cast(typeof(this.red))(red * maxRed!(typeof(this)));
			this.green = cast(typeof(this.green))(green * maxGreen!(typeof(this)));
			this.blue = cast(typeof(this.blue))(blue * maxBlue!(typeof(this)));
			this.alpha = cast(typeof(this.alpha))(alpha * maxAlpha!(typeof(this)));
		}
	}
}

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

@safe pure unittest {
	with(BGR555(1.0, 0.5, 0.0)) {
		assert(red == 31);
		assert(green == 15);
		assert(blue == 0);
	}
}

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
@safe pure unittest {
	with(RGBA8888(1.0, 0.5, 0.0, 0.0)) {
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

struct ColourPair(FG, BG) {
	FG foreground;
	BG background;
	auto contrast() const @safe pure {
		import colourstuff.properties : contrast;
		return contrast(foreground, background);
	}
	bool meetsWCAGAACriteria() const @safe pure {
		return contrast >= 4.5;
	}
	bool meetsWCAGAAACriteria() const @safe pure {
		return contrast >= 7.0;
	}
}

auto colourPair(FG, BG)(FG foreground, BG background) {
	return ColourPair!(FG, BG)(foreground, background);
}

@safe pure unittest {
	import std.math : approxEqual;
	with(colourPair(RGB888(0, 0, 0), RGB888(255, 255, 255))) {
		assert(contrast.approxEqual(21.0));
		assert(meetsWCAGAACriteria);
		assert(meetsWCAGAAACriteria);
	}
	with(colourPair(RGB888(255, 255, 255), RGB888(255, 255, 255))) {
		assert(contrast.approxEqual(1.0));
		assert(!meetsWCAGAACriteria);
		assert(!meetsWCAGAAACriteria);
	}
	with(colourPair(RGB888(0, 128, 255), RGB888(0, 0, 0))) {
		assert(contrast.approxEqual(5.5316));
		assert(meetsWCAGAACriteria);
		assert(!meetsWCAGAAACriteria);
	}
	with(colourPair(BGR555(0, 16, 31), RGB888(0, 0, 0))) {
		assert(contrast.approxEqual(5.7236));
		assert(meetsWCAGAACriteria);
		assert(!meetsWCAGAAACriteria);
	}
}

auto convert(To, From)(From from) {
	static if (is(To == From)) {
		return from;
	} else {
		To output;
		static if ((From.redSize > 0) && (To.redSize > 0)) {
			output.red = colourConvert!(typeof(output.red), To.redSize, From.redSize)(from.red);
		}
		static if ((From.greenSize > 0) && (To.greenSize > 0)) {
			output.green = colourConvert!(typeof(output.green), To.greenSize, From.greenSize)(from.green);
		}
		static if ((From.blueSize > 0) && (To.blueSize > 0)) {
			output.blue = colourConvert!(typeof(output.blue), To.blueSize, From.blueSize)(from.blue);
		}
		static if ((From.alphaSize > 0) && (To.alphaSize > 0)) {
			output.alpha = colourConvert!(typeof(output.alpha), To.alphaSize, From.alphaSize)(from.alpha);
		}
		return output;
	}
}

@safe pure unittest {
	assert(BGR555(31,31,31).convert!RGB888 == RGB888(248, 248, 248));
	assert(BGR555(0, 0, 0).convert!RGB888 == RGB888(0, 0, 0));
	assert(RGB888(248, 248, 248).convert!BGR555 == BGR555(31,31,31));
	assert(RGB888(0, 0, 0).convert!BGR555 == BGR555(0, 0, 0));
}

RGB888 fromHex(const string colour) @safe pure {
	RGB888 output;
	string tmpStr = colour[];
	if (tmpStr.front == '#') {
		tmpStr.popFront();
	}
	if (tmpStr.length == 3) {
		auto tmp = tmpStr[0].repeat(2);
		output.red = tmp.parse!ubyte(16);
		tmp = tmpStr[1].repeat(2);
		output.green = tmp.parse!ubyte(16);
		tmp = tmpStr[2].repeat(2);
		output.blue = tmp.parse!ubyte(16);
	} else if (tmpStr.length == 6) {
		auto tmp = tmpStr[0..2];
		output.red = tmp.parse!ubyte(16);
		tmp = tmpStr[2..4];
		output.green = tmp.parse!ubyte(16);
		tmp = tmpStr[4..6];
		output.blue = tmp.parse!ubyte(16);
	}
	return output;
}

@safe pure unittest {
	assert("#000000".fromHex == RGB888(0, 0, 0));
	assert("#FFFFFF".fromHex == RGB888(255, 255, 255));
	assert("FFFFFF".fromHex == RGB888(255, 255, 255));
	assert("#FFF".fromHex == RGB888(255, 255, 255));
	assert("#888".fromHex == RGB888(0x88, 0x88, 0x88));
	assert("888".fromHex == RGB888(0x88, 0x88, 0x88));
}
