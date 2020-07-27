module magicalrainbows.raw;

import std.conv;

import magicalrainbows.formats;
import magicalrainbows.utils;

enum SupportedFormat { bgr555, bgr565, rgb888, rgba8888, bgr222, bgr333md }

/++
+ Reads and converts a colour from a raw byte array to a specified colour format.
+
+ Params: format = data format to read
+		  data = raw data to read from
+		  ColourFormat = colour format to convert to
+ Returns: a colour in the specified format
+/
auto bytesToColor(ColourFormat = RGB888)(const ubyte[] data, SupportedFormat format) if (isColourFormat!ColourFormat) {
	static ColourFormat getColour(T)(const ubyte[] data) {
		assert(data.length == T.sizeof, "Data length does not match colour size");
		return data.to!(ubyte[T.sizeof]).read!T().convert!ColourFormat();
	}
	final switch (format) {
		case SupportedFormat.bgr222:
			return getColour!BGR222(data);
		case SupportedFormat.bgr333md:
			return getColour!BGR333MD(data);
		case SupportedFormat.bgr555:
			return getColour!BGR555(data);
		case SupportedFormat.bgr565:
			return getColour!BGR565(data);
		case SupportedFormat.rgb888:
			return getColour!RGB888(data);
		case SupportedFormat.rgba8888:
			return getColour!RGBA8888(data);
	}
}
///
@safe pure unittest {
	assert(bytesToColor([0xA9, 0xFF], SupportedFormat.bgr555) == RGB888(72, 232, 248));
	assert(bytesToColor([0xA9, 0xFF], SupportedFormat.bgr565) == RGB888(72, 244, 248));
	assert(bytesToColor([72, 244, 248], SupportedFormat.rgb888) == RGB888(72, 244, 248));
}
auto bytesToColors(ColourFormat = RGB888)(const ubyte[] data, SupportedFormat format) if (isColourFormat!ColourFormat) {
	import std.algorithm.iteration : map;
	import std.array: array;
	import std.range : chunks;
	static ColourFormat[] getPalette(T)(const ubyte[] data) {
		return data.chunks(T.sizeof).map!(x => x.read!T.convert!ColourFormat).array;

	}
	final switch (format) {
		case SupportedFormat.bgr222:
			return getPalette!BGR222(data);
		case SupportedFormat.bgr333md:
			return getPalette!BGR333MD(data);
		case SupportedFormat.bgr555:
			return getPalette!BGR555(data);
		case SupportedFormat.bgr565:
			return getPalette!BGR565(data);
		case SupportedFormat.rgb888:
			return getPalette!RGB888(data);
		case SupportedFormat.rgba8888:
			return getPalette!RGBA8888(data);
	}
}
///
@safe pure unittest {
	assert(bytesToColors([0xA9, 0xFF], SupportedFormat.bgr555) == [RGB888(72, 232, 248)]);
	assert(bytesToColors([0xA9, 0xFF, 0x0, 0x0], SupportedFormat.bgr555) == [RGB888(72, 232, 248), RGB888(0, 0, 0)]);
	assert(bytesToColors([0xA9, 0xFF], SupportedFormat.bgr565) == [RGB888(72, 244, 248)]);
	assert(bytesToColors([72, 244, 248], SupportedFormat.rgb888) == [RGB888(72, 244, 248)]);
}

ubyte[Format.sizeof] colourToBytes(Format)(Format data) if (isColourFormat!Format) {
	return data.asBytes();
}
///
@safe pure unittest {
	assert(colourToBytes(BGR555(9, 29, 31)) == [0xA9, 0x7F]);
	assert(colourToBytes(BGR565(9, 58, 31)) == [0x49, 0xFF]);
	assert(colourToBytes(RGB888(72, 232, 248)) == [72, 232, 248]);
}

ubyte[] colourToBytes(T)(T data, SupportedFormat format) if (isColourFormat!T) {
	ubyte[] output;
	final switch (format) {
		case SupportedFormat.bgr222:
			output = colourToBytes(data.convert!BGR222)[].dup;
			break;
		case SupportedFormat.bgr333md:
			output = colourToBytes(data.convert!BGR333MD)[].dup;
			break;
		case SupportedFormat.bgr555:
			output = colourToBytes(data.convert!BGR555)[].dup;
			break;
		case SupportedFormat.bgr565:
			output = colourToBytes(data.convert!BGR565)[].dup;
			break;
		case SupportedFormat.rgb888:
			output = colourToBytes(data.convert!RGB888)[].dup;
			break;
		case SupportedFormat.rgba8888:
			output = colourToBytes(data.convert!RGBA8888)[].dup;
			break;
	}
	return output;
}
///
@safe pure unittest {
	assert(colourToBytes(RGB888(72, 232, 248), SupportedFormat.bgr555) == [0xA9, 0x7F]);
	assert(colourToBytes(RGB888(72, 232, 248), SupportedFormat.bgr565) == [0x49, 0xFF]);
	assert(colourToBytes(RGB888(72, 232, 248), SupportedFormat.rgb888) == [72, 232, 248]);
}

