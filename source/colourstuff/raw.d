module colourstuff.raw;

import std.conv;
import std.traits;

import colourstuff.formats;

enum SupportedFormat { bgr555, bgr565, rgb888 }

auto bytesToColor(ColourFormat = RGB888)(ubyte[] data, SupportedFormat format) {
	final switch (format) {
		case SupportedFormat.bgr555:
			assert(data.length == BGR555.sizeof, "Bad length for BGR555");
			return data.to!(ubyte[BGR555.sizeof]).read!BGR555().convert!ColourFormat();
		case SupportedFormat.bgr565:
			assert(data.length == BGR565.sizeof, "Bad length for BGR565");
			return data.to!(ubyte[BGR565.sizeof]).read!BGR565().convert!ColourFormat();
		case SupportedFormat.rgb888:
			assert(data.length == RGB888.sizeof, "Bad length for RGB888");
			return data.to!(ubyte[RGB888.sizeof]).read!RGB888().convert!ColourFormat();
	}
}

@safe pure unittest {
	assert(bytesToColor([0xA9, 0xFF], SupportedFormat.bgr555) == RGB888(72, 232, 248));
	assert(bytesToColor([0xA9, 0xFF], SupportedFormat.bgr565) == RGB888(72, 244, 248));
	assert(bytesToColor([72, 244, 248], SupportedFormat.rgb888) == RGB888(72, 244, 248));
}

ubyte[Format.sizeof] colourToBytes(Format)(Format data) {
	return data.asBytes();
}

@safe pure unittest {
	assert(colourToBytes(BGR555(9, 29, 31)) == [0xA9, 0x7F]);
	assert(colourToBytes(BGR565(9, 58, 31)) == [0x49, 0xFF]);
	assert(colourToBytes(RGB888(72, 232, 248)) == [72, 232, 248]);
}

ubyte[] colourToBytes(T)(T data, SupportedFormat format) {
	ubyte[] output;
	final switch (format) {
		case SupportedFormat.bgr555:
			output = colourToBytes(data.convert!BGR555)[].dup;
			break;
		case SupportedFormat.bgr565:
			output = colourToBytes(data.convert!BGR565)[].dup;
			break;
		case SupportedFormat.rgb888:
			output = colourToBytes(data.convert!RGB888)[].dup;
			break;
	}
	return output;
}

@safe pure unittest {
	assert(colourToBytes(RGB888(72, 232, 248), SupportedFormat.bgr555) == [0xA9, 0x7F]);
	assert(colourToBytes(RGB888(72, 232, 248), SupportedFormat.bgr565) == [0x49, 0xFF]);
	assert(colourToBytes(RGB888(72, 232, 248), SupportedFormat.rgb888) == [72, 232, 248]);
}

private T read(T)(ubyte[] input) if (isMutable!T) in {
	assert(input.length == T.sizeof, "Mismatch between input buffer size and expected value size");
} body {
	union Result {
		ubyte[T.sizeof] raw;
		T val;
	}
	Result result;
	result.raw = input;
	return result.val;
}

private ubyte[T.sizeof] asBytes(T)(T input) if (isMutable!T) {
	union Result {
		ubyte[T.sizeof] raw;
		T val;
	}
	Result result;
	result.val = input;
	return result.raw;
}
