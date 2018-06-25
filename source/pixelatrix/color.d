module pixelatrix.color;

import std.bitmanip;
import std.conv;

auto rgb(ubyte red, ubyte green, ubyte blue) pure {
	return RGB888(red, green, blue);
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
ubyte[] colorToBytes(RGB888 data, string format, ulong size) pure @safe {
	ubyte[] output = new ubyte[](cast(size_t)size);
	switch (format) {
		case "BGR555":
			output[0] = cast(ubyte)((data.red>>3) | ((data.green>>3)<<5));
			output[1] = cast(ubyte)((data.green>>6) | ((data.blue>>3)<<2));
			break;
		default: throw new Exception("Unknown format");
	}
	return output;
}
///
@safe pure unittest {
	assert(colorToBytes(rgb(72, 232, 248), "BGR555", 2) == [0xA9, 0x7F]);
}