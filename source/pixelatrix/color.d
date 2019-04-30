module pixelatrix.color;

import std.bitmanip;
import std.conv;

auto rgb(ubyte red, ubyte green, ubyte blue) pure {
	return RGB888(red, green, blue);
}

enum Format {
	Invalid,
	BGR555,
	BGR565,
	RGB888,
	RGBA8888
}

mixin template colourConstructors() {
	this(double r, double g, double b) @safe pure {
		red = cast(typeof(red))(r * cast(double)maxValueForBits(redSize));
		green = cast(typeof(green))(g * cast(double)maxValueForBits(greenSize));
		blue = cast(typeof(blue))(b * cast(double)maxValueForBits(blueSize));
	}
	this(ubyte r, ubyte g, ubyte b) @safe pure {
		red = r;
		green = g;
		blue = b;
	}
}

align(1)
struct BGR555 { //XBBBBBGG GGGRRRRR
	enum redSize = 5;
	enum greenSize = 5;
	enum blueSize = 5;
	mixin(bitfields!(
		uint, "red", redSize,
		uint, "green", greenSize,
		uint, "blue", blueSize,
		bool, "padding", 1));
	mixin colourConstructors;
}

align(1)
struct BGR565 { //BBBBBGGG GGGRRRRR
	enum redSize = 5;
	enum greenSize = 6;
	enum blueSize = 5;
	mixin(bitfields!(
		uint, "red", redSize,
		uint, "green", greenSize,
		uint, "blue", blueSize));
	mixin colourConstructors;
}

align(1)
struct RGB888 { //RRRRRRRR GGGGGGGG BBBBBBBB
	align(1):
	enum redSize = 8;
	enum greenSize = 8;
	enum blueSize = 8;
	ubyte red;
	ubyte green;
	ubyte blue;
	mixin colourConstructors;
}
align(1)
struct RGBA8888 { //RRRRRRRR GGGGGGGG BBBBBBBB AAAAAAAA
	align(1):
	enum redSize = 8;
	enum greenSize = 8;
	enum blueSize = 8;
	enum alphaSize = 8;
	ubyte red;
	ubyte green;
	ubyte blue;
	ubyte alpha;
	mixin colourConstructors;
}
/++
+ Reads and converts a colour from a raw byte array to an RGB888 colour.
+
+ Params: Format = data format to read
+		  data = raw data to read from
+ Returns: a 24-bit RGB colour.
+/
RGB888 bytesToRGB888(Format)(ubyte[Format.sizeof] data) {
	union RawRead {
		Format format;
		ubyte[Format.sizeof] raw;
	}
	auto output = RGB888();
	RawRead raw;
	raw.raw = data;
	const readColor = raw.format;
	output.red = cast(ubyte)(readColor.red<<(8-Format.redSize));
	output.green = cast(ubyte)(readColor.green<<(8-Format.greenSize));
	output.blue = cast(ubyte)(readColor.blue<<(8-Format.blueSize));
	return output;
}
enum SupportedFormat { bgr555, bgr565, rgb888 }
auto bytesToColor(ubyte[] data, SupportedFormat format) {
	final switch (format) {
		case SupportedFormat.bgr555:
			assert(data.length == BGR555.sizeof, "Bad length for BGR555");
			return bytesToRGB888!BGR555(data.to!(ubyte[BGR555.sizeof]));
		case SupportedFormat.bgr565:
			assert(data.length == BGR565.sizeof, "Bad length for BGR565");
			return bytesToRGB888!BGR565(data.to!(ubyte[BGR565.sizeof]));
		case SupportedFormat.rgb888:
			assert(data.length == RGB888.sizeof, "Bad length for RGB888");
			return bytesToRGB888!RGB888(data.to!(ubyte[RGB888.sizeof]));
	}
}
///
@safe pure unittest {
	assert(bytesToColor([0xA9, 0xFF], SupportedFormat.bgr555) == rgb(72, 232, 248));
	assert(bytesToColor([0xA9, 0xFF], SupportedFormat.bgr565) == rgb(72, 244, 248));
}
ubyte[] colorToBytes(T)(T colour, Format format, ulong size) pure @safe {
	ubyte[] output = new ubyte[](cast(size_t)size);
	final switch (format) {
		case Format.Invalid:
			assert(0, "Invalid format");
		case Format.BGR555:
			assert(size == BGR555.sizeof, "Invalid size specified");
			output[] = colorToBytes(convertColour!BGR555(colour));
			break;
		case Format.BGR565:
			assert(size == BGR565.sizeof, "Invalid size specified");
			output[] = colorToBytes(convertColour!BGR565(colour));
			break;
		case Format.RGB888:
			assert(size == RGB888.sizeof, "Invalid size specified");
			output[] = colorToBytes(convertColour!RGB888(colour));
			break;
		case Format.RGBA8888:
			assert(size == RGBA8888.sizeof, "Invalid size specified");
			output[] = colorToBytes(convertColour!RGBA8888(colour));
			break;
	}
	return output;
}
///
@safe pure unittest {
	assert(colorToBytes(rgb(72, 232, 248), Format.BGR555, 2) == [0xA9, 0x7F]);
}
auto colorToBytes(T)(T data) pure @safe {
	union Raw {
		T colour;
		ubyte[T.sizeof] raw;
	}
	//Raw raw;
	//raw.colour = data;
	return Raw(data).raw;
}
///
@safe pure unittest {
	assert(colorToBytes(BGR555(9, 29, 31)) == [0xA9, 0x7F]);
}

T convertColour(T, U)(U input) {
	T output;
	static if (T.redSize > U.redSize) {
		output.red = input.red << (T.redSize - U.redSize);
	} else {
		output.red = input.red >> (U.redSize - T.redSize);
	}
	static if (T.greenSize > U.greenSize) {
		output.green = input.green << (T.greenSize - U.greenSize);
	} else {
		output.green = input.green >> (U.greenSize - T.greenSize);
	}
	static if (T.blueSize > U.blueSize) {
		output.blue = input.blue << (T.blueSize - U.blueSize);
	} else {
		output.blue = input.blue >> (U.blueSize - T.blueSize);
	}
	return output;
}

@safe unittest {
	assert(convertColour!BGR565(BGR555(31,31,31)) == BGR565(31,62,31));
}

ulong maxValueForBits(ulong n) @safe pure {
	return (1 << n) - 1;
}

struct HSV {
    double hue;
    double saturation;
    double value;
}

auto toHSV(T)(T input)
{
	import std.algorithm.comparison : max, min;
	import std.math : approxEqual;
    HSV result;
    const red = cast(double)input.red / cast(double)maxValueForBits(T.redSize);
    const green = cast(double)input.green / cast(double)maxValueForBits(T.greenSize);
    const blue = cast(double)input.blue / cast(double)maxValueForBits(T.blueSize);
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

    return result;
}

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


auto toRGB(T)(HSV input)
{
    T convertColour(double r, double g, double b) @safe {
		T output;
		output.red = cast(typeof(T.red))(r * cast(double)maxValueForBits(T.redSize));
		output.green = cast(typeof(T.green))(g * cast(double)maxValueForBits(T.greenSize));
		output.blue = cast(typeof(T.blue))(b * cast(double)maxValueForBits(T.blueSize));
		return output;
    }

    if(input.saturation <= 0.0) {
        return convertColour(input.value, input.value, input.value);
    }
    double hh = input.hue * 6.0;
    if(hh > 6.0) {
		hh	 = 0.0;
    }
    auto i = cast(long)hh;
    double ff = hh - i;
    double p = input.value * (1.0 - input.saturation);
    double q = input.value * (1.0 - (input.saturation * ff));
    double t = input.value * (1.0 - (input.saturation * (1.0 - ff)));

    assert(p < 1.0);
    assert(q < 1.0);
    assert(t < 1.0);

    switch(i) {
		case 0:
			return convertColour(input.value, t, p);
		case 1:
			return convertColour(q, input.value, p);
		case 2:
			return convertColour(p, input.value, t);
		case 3:
			return convertColour(p, q, input.value);
		case 4:
			return convertColour(t, p, input.value);
		case 5:
		default:
			return convertColour(input.value, p, q);
    }
}

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
