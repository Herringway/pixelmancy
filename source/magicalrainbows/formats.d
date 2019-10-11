module magicalrainbows.formats;

import magicalrainbows.utils;

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


struct HSV {
    double hue;
    double saturation;
    double value;
    invariant() {
    	assert(hue >= 0);
    	assert(saturation >= 0);
    	assert(value >= 0);
    	assert(hue <= 1.0);
    	assert(saturation <= 1.0);
    	assert(value <= 1.0);
    }
}

auto toHSV(Format)(Format input) if (isColourFormat!Format) {
	import std.algorithm.comparison : max, min;
	import std.math : approxEqual;
    HSV result;
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

    if (approxEqual(red, maximum)) {
        result.hue = (green - blue) / delta; //yellow, magenta
    } else if (approxEqual(green, maximum)) {
        result.hue = 2.0 + (blue - red) / delta; //cyan,  yellow
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
	import std.math : approxEqual;
	with(RGB888(0, 0, 0).toHSV) {
		assert(hue == 0);
		assert(saturation == 0);
		assert(value == 0);
	}
	with(RGB888(0, 128, 192).toHSV) {
		assert(approxEqual(hue, 0.5555555));
		assert(approxEqual(saturation, 1.0));
		assert(approxEqual(value, 0.752941));
	}
}

auto toRGB(Format = RGB888)(HSV input) if (isColourFormat!Format) {
    if(input.saturation <= 0.0) {
        return Format(input.value, input.value, input.value);
    }
    real hh = input.hue * 6.0;
    if(hh > 6.0) {
		hh	 = 0.0;
    }
    auto i = cast(long)hh;
    real ff = hh - i;
    real p = input.value * (1.0 - input.saturation);
    real q = input.value * (1.0 - (input.saturation * ff));
    real t = input.value * (1.0 - (input.saturation * (1.0 - ff)));

    assert(p <= 1.0);
    assert(q <= 1.0);
    assert(t <= 1.0);
    switch(i) {
		case 0:
			return Format(input.value, t, p);
		case 1:
			return Format(q, input.value, p);
		case 2:
			return Format(p, input.value, t);
		case 3:
			return Format(p, q, input.value);
		case 4:
			return Format(t, p, input.value);
		case 5:
		default:
			return Format(input.value, p, q);
    }
}
///
@safe unittest {
	with(HSV(0, 0, 0).toRGB!RGB888) {
		assert(red == 0);
		assert(green == 0);
		assert(blue == 0);
	}
	with(HSV(0, 0, 0.5).toRGB!RGB888) {
		assert(red == 127);
		assert(green == 127);
		assert(blue == 127);
	}
	with(HSV(0.5555555, 1.0, 0.752941).toRGB!RGB888) {
		assert(red == 0);
		assert(green == 128);
		assert(blue == 191);
	}
}

struct ColourPair(FG, BG) if (isColourFormat!FG && isColourFormat!BG) {
	FG foreground;
	BG background;
	auto contrast() const @safe pure {
		import magicalrainbows.properties : contrast;
		return contrast(foreground, background);
	}
	bool meetsWCAGAACriteria() const @safe pure {
		return contrast >= 4.5;
	}
	bool meetsWCAGAAACriteria() const @safe pure {
		return contrast >= 7.0;
	}
}

auto colourPair(FG, BG)(FG foreground, BG background) if (isColourFormat!FG && isColourFormat!BG) {
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

auto convert(To, From)(From from) if (isColourFormat!From && isColourFormat!To) {
	static if (is(To == From)) {
		return from;
	} else {
		To output;
		static if (hasRed!From && hasRed!To) {
			output.red = colourConvert!(typeof(output.red), To.redSize, From.redSize)(from.red);
		}
		static if (hasGreen!From && hasGreen!To) {
			output.green = colourConvert!(typeof(output.green), To.greenSize, From.greenSize)(from.green);
		}
		static if (hasBlue!From && hasBlue!To) {
			output.blue = colourConvert!(typeof(output.blue), To.blueSize, From.blueSize)(from.blue);
		}
		static if (hasAlpha!From && hasAlpha!To) {
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

Format fromHex(Format = RGB888)(const string colour) @safe pure if (isColourFormat!Format) {
	Format output;
	string tmpStr = colour[];
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
