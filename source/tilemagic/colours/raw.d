///
module tilemagic.colours.raw;

import std.conv;
import std.system;

import tilemagic.colours.formats;
import tilemagic.colours.utils;

enum SupportedFormat { bgr555, bgr565, rgb24, rgba8888, bgr222, bgr333md }

/++
+ Reads a colour from a raw byte array to a specified colour format.
+
+ Params: format = data format to read
+		data = raw data to read from
+		ColourFormat = colour format to convert to
+ Returns: a colour in the specified format
+/
ColourFormat bytesToColour(ColourFormat = RGB24)(const ubyte[] data) if (isColourFormat!ColourFormat) {
	const result = bytesToColours!ColourFormat(data);
	assert(result.length == 1);
	return result[0];
}
/// ditto
alias bytesToColor = bytesToColour;
///
@safe pure unittest {
	assert(bytesToColour!BGR555([0xA9, 0xFF]) == BGR555(red: 9, green: 29, blue: 31));
	assert(bytesToColour!BGR565([0xA9, 0xFF]) == BGR565(red: 9, green: 61, blue: 31));
	assert(bytesToColour!RGB24([72, 244, 248]) == RGB24(72, 244, 248));
}
/**
* Reinterprets an array of bytes as an array of colours.
* Params: data = Raw bytes to reinterpret
*/
const(ColourFormat)[] bytesToColours(ColourFormat = RGB24)(const ubyte[] data) if (isColourFormat!ColourFormat) {
	return cast(const(ColourFormat)[])data;
}
/// ditto
alias bytesToColors = bytesToColours;
///
@safe pure unittest {
	assert(bytesToColours!BGR555([0xA9, 0xFF]) == [BGR555(red: 9, green: 29, blue: 31)]);
	assert(bytesToColours!BGR555([0xA9, 0xFF, 0x0, 0x0]) == [BGR555(red: 9, green: 29, blue: 31), BGR555(0, 0, 0)]);
	assert(bytesToColours!BGR565([0xA9, 0xFF]) == [BGR565(red: 9, green: 61, blue: 31)]);
	assert(bytesToColours!RGB24([72, 244, 248]) == [RGB24(red: 72, green: 244, blue: 248)]);
}

ubyte[Format.sizeof] colourToBytes(Format)(Format data) if (isColourFormat!Format) {
	import tilemagic.colours.utils : asBytes;
	return data.asBytes();
}
/// ditto
alias colorToBytes = colourToBytes;
///
@safe pure unittest {
	assert(colourToBytes(BGR555(9, 29, 31)) == [0xA9, 0x7F]);
	assert(colourToBytes(BGR565(9, 58, 31)) == [0x49, 0xFF]);
	assert(colourToBytes(RGB24(red: 72, green: 232, blue: 248)) == [72, 232, 248]);
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
		case SupportedFormat.rgb24:
			output = colourToBytes(data.convert!RGB24)[].dup;
			break;
		case SupportedFormat.rgba8888:
			output = colourToBytes(data.convert!RGBA8888)[].dup;
			break;
	}
	return output;
}
///
@safe pure unittest {
	assert(colourToBytes(RGB24(red: 72, green: 232, blue: 248), SupportedFormat.bgr555) == [0xA9, 0x7F]);
	assert(colourToBytes(RGB24(red: 72, green: 232, blue: 248), SupportedFormat.bgr565) == [0x49, 0xFF]);
	assert(colourToBytes(RGB24(red: 72, green: 232, blue: 248), SupportedFormat.rgb24) == [72, 232, 248]);
}

///
ColourFormat integerToColour(ColourFormat, Endian endianness = endian)(ClosestInteger!(ColourFormat.sizeof) integer) if (isColourFormat!ColourFormat){
	import std.bitmanip : nativeToBigEndian, nativeToLittleEndian;
	ubyte[typeof(integer).sizeof] bytes = endianness == Endian.littleEndian ? nativeToLittleEndian(integer) : nativeToBigEndian(integer);
	return bytesToColour!ColourFormat(bytes[]);
}
/// ditto
alias integerToColor = integerToColour;
///
@safe pure unittest {
	assert(integerToColour!BGR555(0x7FFF) == BGR555(red: 31, green: 31, blue: 31));
	assert(integerToColour!BGR555(0x3FFF) == BGR555(red: 31, green: 31, blue: 15));
}

///
ClosestInteger!(ColourFormat.sizeof) colourToInteger(Endian endianness = endian, ColourFormat)(ColourFormat colour) if (isColourFormat!ColourFormat) {
	import std.bitmanip : bigEndianToNative, littleEndianToNative;
	auto raw = colourToBytes(colour);
	return endianness == Endian.littleEndian ? littleEndianToNative!(typeof(return))(raw) : bigEndianToNative!(typeof(return))(raw);
}
/// ditto
alias colorToInteger = colourToInteger;
///
@safe pure unittest {
	assert(colourToInteger(BGR555(red: 31, green: 31, blue: 31)) == 0x7FFF);
	assert(colourToInteger(BGR555(red: 31, green: 31, blue: 15)) == 0x3FFF);
}
