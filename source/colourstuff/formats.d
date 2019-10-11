module colourstuff.formats;

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

private T colourConvert(T, size_t Size1, size_t Size2, Source)(Source val ) {
	static if (Size1 > Size2) {
		return cast(T)(val << (Size1 - Size2));
	} else static if (Size1 < Size2) {
		return cast(T)(val >> (Size2 - Size1));
	} else {
		return cast(T)val;
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
