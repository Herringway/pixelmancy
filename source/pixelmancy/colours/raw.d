///
module pixelmancy.colours.raw;

import std.conv;
import std.string;
import std.system;
import std.traits;

import pixelmancy.colours.formats;
import pixelmancy.colours.utils;

enum SupportedFormat {
	bgr555,
	rgb555,
	bgr565,
	bgr222,
	bgr333md,
	rgb24,
	rgba32,
	argb32,
	bgr24,
	bgra32,
	abgr32,
	rgba8888,
	argb8888,
	bgra8888,
	abgr8888,
}

/++
+ Reads a colour from a raw byte array to a specified colour format.
+
+ Params: format = data format to read
+		data = raw data to read from
+		ColourFormat = colour format to convert to
+ Returns: a colour in the specified format
+/
ColourFormat bytesToColour(ColourFormat = RGB24)(const ubyte[] data, SupportedFormat format) if (isRGBColourFormat!ColourFormat) {
	const result = bytesToColours!ColourFormat(data, format);
	assert(result.length == 1);
	return result[0];
}
/// ditto
ColourFormat bytesToColour(ColourFormat = RGB24)(const ubyte[] data) if (isRGBColourFormat!ColourFormat) {
	static foreach (format; EnumMembers!SupportedFormat) {
		static if (is(mixin(format.stringof.toUpper) == ColourFormat)) {
			return bytesToColour!ColourFormat(data, format);
		}
	}
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
ColourFormat[] bytesToColours(ColourFormat = RGB24)(const ubyte[] data, SupportedFormat format) if (isRGBColourFormat!ColourFormat) {
	final switch (format) {
		static foreach (fmt; EnumMembers!SupportedFormat) {
			case fmt:
				alias Fmt = mixin(fmt.stringof.toUpper);
				ColourFormat[] output;
				output.reserve(data.length / Fmt.sizeof);
				foreach (reinterpreted; cast(const(Fmt)[])data) {
					output ~= reinterpreted.convert!ColourFormat;
				}
				return output;
		}
	}
}
/// ditto
ColourFormat[] bytesToColours(ColourFormat = RGB24)(const ubyte[] data) if (isRGBColourFormat!ColourFormat) {
	static foreach (format; EnumMembers!SupportedFormat) {
		static if (is(mixin(format.stringof.toUpper) == ColourFormat)) {
			return bytesToColours!ColourFormat(data, format);
		}
	}
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

ubyte[Format.sizeof] colourToBytes(Format)(Format data) if (isRGBColourFormat!Format) {
	import pixelmancy.colours.utils : asBytes;
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

ubyte[] colourToBytes(T)(T data, SupportedFormat format) if (isRGBColourFormat!T) {
	final switch (format) {
		static foreach (fmt; EnumMembers!SupportedFormat) {
			case fmt: return colourToBytes(data.convert!(mixin(fmt.stringof.toUpper)))[].dup;
		}
	}
}
///
@safe pure unittest {
	assert(colourToBytes(RGB24(red: 72, green: 232, blue: 248), SupportedFormat.bgr555) == [0xA9, 0x7F]);
	assert(colourToBytes(RGB24(red: 72, green: 232, blue: 248), SupportedFormat.bgr565) == [0x49, 0xFF]);
	assert(colourToBytes(RGB24(red: 72, green: 232, blue: 248), SupportedFormat.rgb24) == [72, 232, 248]);
}

size_t colourSize(SupportedFormat format) @safe pure {
	final switch (format) {
		static foreach (fmt; EnumMembers!SupportedFormat) {
			case fmt: return mixin(fmt.stringof.toUpper).sizeof;
		}
	}
}
///
@safe pure unittest {
	assert(colourSize(SupportedFormat.rgb24) == RGB24.sizeof);
	assert(colourSize(SupportedFormat.rgba32) == RGBA32.sizeof);
}

///
ColourFormat integerToColour(ColourFormat, Endian endianness = endian)(ClosestInteger!(ColourFormat.sizeof) integer) if (isRGBColourFormat!ColourFormat){
	import std.bitmanip : nativeToBigEndian, nativeToLittleEndian;
	ubyte[typeof(integer).sizeof] bytes = endianness == Endian.littleEndian ? nativeToLittleEndian(integer) : nativeToBigEndian(integer);
	return bytesToColour!ColourFormat(bytes[0 .. ColourFormat.sizeof]);
}
/// ditto
alias integerToColor = integerToColour;
///
@safe pure unittest {
	import std.bitmanip : swapEndian;
	assert(integerToColour!BGR555(0x7FFF) == BGR555(red: 31, green: 31, blue: 31));
	assert(integerToColour!RGB24(0xFDFEFF) == RGB24(red: 255, green: 254, blue: 253));
	assert(integerToColour!BGR555(0x3FFF) == BGR555(red: 31, green: 31, blue: 15));
	version(LittleEndian) {
		enum ushort littleEndianValue = 0x7FFF;
		enum ushort bigEndianValue = swapEndian(littleEndianValue);
		enum uint littleEndianValue2 = 0xFDFEFF;
		enum uint bigEndianValue2 = swapEndian(littleEndianValue2);
	} else {
		enum ushort bigEndianValue = 0x7FFF;
		enum ushort littleEndianValue = swapEndian(bigEndianValue);
		enum uint bigEndianValue2 = 0xFDFEFF;
		enum uint littleEndianValue2 = swapEndian(bigEndianValue2);
	}
	assert(integerToColour!(BGR555, Endian.littleEndian)(littleEndianValue) == BGR555(red: 31, green: 31, blue: 31));
	assert(integerToColour!(BGR555, Endian.bigEndian)(bigEndianValue) == BGR555(red: 31, green: 31, blue: 31));
	assert(integerToColour!(RGB24, Endian.littleEndian)(littleEndianValue2) == RGB24(red: 255, green: 254, blue: 253));
	assert(integerToColour!(RGB24, Endian.bigEndian)(bigEndianValue2) == RGB24(red: 255, green: 254, blue: 253));
}

///
ClosestInteger!(ColourFormat.sizeof) colourToInteger(Endian endianness = endian, ColourFormat)(ColourFormat colour) if (isRGBColourFormat!ColourFormat) {
	import std.bitmanip : bigEndianToNative, littleEndianToNative;
	ubyte[typeof(return).sizeof] raw;
	raw[(!endian) * (typeof(return).sizeof - ColourFormat.sizeof) .. $ - (endian) * (typeof(return).sizeof - ColourFormat.sizeof)] = colourToBytes(colour);
	return endianness == Endian.littleEndian ? littleEndianToNative!(typeof(return))(raw) : bigEndianToNative!(typeof(return))(raw);
}
/// ditto
alias colorToInteger = colourToInteger;
///
@safe pure unittest {
	enum rgb24Value = RGB24(red: 255, green: 254, blue: 253);
	enum rgb24ExpectedInteger = 0xFDFEFF;
	enum bgr555Value = BGR555(red: 31, green: 30, blue: 29);
	enum bgr555ExpectedInteger = 0x77DF;
	import std.bitmanip : swapEndian;
	assert(colourToInteger(bgr555Value) == bgr555ExpectedInteger);
	assert(colourToInteger(rgb24Value) == rgb24ExpectedInteger);
	version(LittleEndian) {
		enum ushort littleEndianValue = bgr555ExpectedInteger;
		enum ushort bigEndianValue = swapEndian(littleEndianValue);
		enum uint littleEndianValue2 = rgb24ExpectedInteger;
		enum uint bigEndianValue2 = swapEndian(littleEndianValue2);
	} else {
		enum ushort bigEndianValue = bgr555ExpectedInteger;
		enum ushort littleEndianValue = swapEndian(bigEndianValue);
		enum uint bigEndianValue2 = rgb24ExpectedInteger;
		enum uint littleEndianValue2 = swapEndian(bigEndianValue2);
	}
	assert(colourToInteger!(Endian.littleEndian)(bgr555Value) == littleEndianValue);
	assert(colourToInteger!(Endian.bigEndian)(bgr555Value) == bigEndianValue);
	assert(colourToInteger!(Endian.littleEndian)(rgb24Value) == littleEndianValue2);
	assert(colourToInteger!(Endian.bigEndian)(rgb24Value) == bigEndianValue2);
}
