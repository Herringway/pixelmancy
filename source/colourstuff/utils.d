module colourstuff.utils;

import std.traits;

package:

T read(T)(ubyte[] input) if (isMutable!T) in {
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

ubyte[T.sizeof] asBytes(T)(T input) if (isMutable!T) {
	union Result {
		ubyte[T.sizeof] raw;
		T val;
	}
	Result result;
	result.val = input;
	return result.raw;
}

enum maxValue(ulong Bits) = (1<<Bits) - 1;

enum maxRed(T) = maxValue!(T.redSize);
enum maxGreen(T) = maxValue!(T.greenSize);
enum maxBlue(T) = maxValue!(T.blueSize);
enum maxAlpha(T) = maxValue!(T.alphaSize);

real redFP(Colour)(const Colour colour) {
	return (cast(real)colour.red / maxRed!Colour);
}

real greenFP(Colour)(const Colour colour) {
	return (cast(real)colour.green / maxGreen!Colour);
}

real blueFP(Colour)(const Colour colour) {
	return (cast(real)colour.blue / maxBlue!Colour);
}
@safe pure unittest {
	import colourstuff.formats : RGB888;
	import std.math : approxEqual;
	assert(RGB888(255, 128, 0).redFP() == 1.0);
	assert(RGB888(255, 128, 0).greenFP().approxEqual(0.502));
	assert(RGB888(255, 128, 0).blueFP() == 0.0);
	assert(RGB888(0, 255, 128).redFP() == 0.0);
	assert(RGB888(0, 255, 128).greenFP() == 1.0);
	assert(RGB888(0, 255, 128).blueFP().approxEqual(0.502));
	assert(RGB888(128, 0, 255).redFP().approxEqual(0.502));
	assert(RGB888(128, 0, 255).greenFP() == 0.0);
	assert(RGB888(128, 0, 255).blueFP() == 1.0);
}

real toLinearRGB(const real input) @safe pure @nogc nothrow {
	return input > 0.03928 ?
		((input + 0.055) / 1.055)^^2.4 :
		input / 12.92 ;
}


T colourConvert(T, size_t Size1, size_t Size2, Source)(Source val ) {
	static if (Size1 > Size2) {
		return cast(T)(val << (Size1 - Size2));
	} else static if (Size1 < Size2) {
		return cast(T)(val >> (Size2 - Size1));
	} else {
		return cast(T)val;
	}
}
