module colourstuff.raw;

import std.conv;
import std.traits;

import colourstuff.formats;

auto rgb(ubyte red, ubyte green, ubyte blue) pure {
	return RGB888(red, green, blue);
}
RGB888 bytesToRGB888(Format)(ubyte[Format.sizeof] data) {
	//auto output = RGB888();
	return data.read!Format.toRGB888;
	//output.red = cast(ubyte)(readColor.red<<(8-Format.redSize));
	//output.green = cast(ubyte)(readColor.green<<(8-Format.greenSize));
	//output.blue = cast(ubyte)(readColor.blue<<(8-Format.blueSize));
	//return output;
}
enum SupportedFormat { bgr555, bgr565, rgb888 }
auto bytesToColor(ubyte[] data, SupportedFormat format) pure {
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
unittest {
	assert(bytesToColor([0xA9, 0xFF], SupportedFormat.bgr555) == rgb(72, 232, 248));
	assert(bytesToColor([0xA9, 0xFF], SupportedFormat.bgr565) == rgb(72, 244, 248));
}
ubyte[Format.sizeof] colorToBytes(Format)(uint data) {
	return [];
}
ubyte[] colorToBytes(RGB888 data, string format, ulong size) pure {
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
unittest {
	assert(colorToBytes(rgb(72, 232, 248), "BGR555", 2) == [0xA9, 0x7F]);
}

private T read(T)(ubyte[] input, T val) @nogc if (isMutable!T) in {
	assert(input.length == T.sizeof, "Mismatch between input buffer size and expected value size");
} body {
	auto mVal = (cast(void*)&val)[0..val.sizeof];
	foreach (i, byteValue; input)
		(cast(ubyte[])mVal)[i] = byteValue;
	return val;
}
private T read(T)(ubyte[T.sizeof] input) @nogc if (isMutable!T) {
	T val;
	return read(input[], val);
}