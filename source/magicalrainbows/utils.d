module magicalrainbows.utils;

import std.traits;

package:

T read(T)(const ubyte[] input) if (isMutable!T) in {
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
		T val;
		ubyte[T.sizeof] raw;
	}
	return Result(input).raw;
}

enum isColourFormat(T) = hasRed!T && hasGreen!T && hasBlue!T;

enum hasRed(T) = __traits(hasMember, T, "redSize") && (T.redSize > 0);
enum hasGreen(T) = __traits(hasMember, T, "greenSize") && (T.greenSize > 0);
enum hasBlue(T) = __traits(hasMember, T, "blueSize") && (T.blueSize > 0);
enum hasAlpha(T) = __traits(hasMember, T, "alphaSize") && (T.alphaSize > 0);

enum maxValue(ulong Bits) = (1<<Bits) - 1;

enum maxRed(T) = maxValue!(T.redSize);
enum maxGreen(T) = maxValue!(T.greenSize);
enum maxBlue(T) = maxValue!(T.blueSize);
enum maxAlpha(T) = maxValue!(T.alphaSize);

enum isDigital(T) = hasRed!T && hasGreen!T && hasBlue!T;

real redFP(Colour)(const Colour colour) if (hasRed!Colour) {
	return (cast(real)colour.red / maxRed!Colour);
}

real greenFP(Colour)(const Colour colour) if (hasGreen!Colour) {
	return (cast(real)colour.green / maxGreen!Colour);
}

real blueFP(Colour)(const Colour colour) if (hasBlue!Colour) {
	return (cast(real)colour.blue / maxBlue!Colour);
}
real alphaFP(Colour)(const Colour colour) if (hasAlpha!Colour) {
	return (cast(real)colour.alpha / maxAlpha!Colour);
}
@safe pure unittest {
	import magicalrainbows.formats : RGB888;
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

auto asLinearRGB(Format)(const Format colour) {
	static if (isDigital!Format) {
		const red = colour.redFP.toLinearRGB;
		const green = colour.greenFP.toLinearRGB;
		const blue = colour.blueFP.toLinearRGB;
		static if (hasAlpha!Format) {
			const alpha = colour.alphaFP.toLinearRGB;
		}
	} else {
		const red = colour.red.toLinearRGB;
		const green = colour.green.toLinearRGB;
		const blue = colour.blue.toLinearRGB;
		static if (hasAlpha!Format) {
			const alpha = colour.alpha.toLinearRGB;
		}
	}
	static if (hasAlpha!Format) {
		import magicalrainbows.formats : AnalogRGBA;
		return AnalogRGBA(red, green, blue, alpha);
	} else {
		import magicalrainbows.formats : AnalogRGB;
		return AnalogRGB(red, green, blue);
	}
}

private real toLinearRGB(const real input) @safe pure @nogc nothrow {
	return input > 0.03928 ?
		((input + 0.055) / 1.055) ^^ 2.4 :
		input / 12.92 ;
}

private real gammaCorrect(const real input, const real factor = 2.2) @safe pure @nogc nothrow {
	return input ^^ (1.0 / factor);
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
	this(const AnalogRGB analog) pure @safe
		in(analog.red <= 1.0, "Red value out of range")
		in(analog.red >= 0.0, "Red value out of range")
		in(analog.green <= 1.0, "Green value out of range")
		in(analog.green >= 0.0, "Green value out of range")
		in(analog.blue <= 1.0, "Blue value out of range")
		in(analog.blue >= 0.0, "Blue value out of range")
	{
		this.red = cast(typeof(this.red))(analog.red * maxRed!(typeof(this)));
		this.green = cast(typeof(this.green))(analog.green * maxGreen!(typeof(this)));
		this.blue = cast(typeof(this.blue))(analog.blue * maxBlue!(typeof(this)));
	}
	auto opCast(T: AnalogRGB)() const {
		return AnalogRGB(this.redFP, this.greenFP, this.blueFP);
	}
	static if (hasAlpha!(typeof(this))) {
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
		this(AnalogRGBA analog) pure @safe
			in(analog.red <= 1.0, "Red value out of range")
			in(analog.red >= 0.0, "Red value out of range")
			in(analog.green <= 1.0, "Green value out of range")
			in(analog.green >= 0.0, "Green value out of range")
			in(analog.blue <= 1.0, "Blue value out of range")
			in(analog.blue >= 0.0, "Blue value out of range")
			in(analog.alpha <= 1.0, "Blue value out of range")
			in(analog.alpha >= 0.0, "Blue value out of range")
		{
			this.red = cast(typeof(this.red))(analog.red * maxRed!(typeof(this)));
			this.green = cast(typeof(this.green))(analog.green * maxGreen!(typeof(this)));
			this.blue = cast(typeof(this.blue))(analog.blue * maxBlue!(typeof(this)));
			this.alpha = cast(typeof(this.alpha))(analog.alpha * maxAlpha!(typeof(this)));
		}
		auto opCast(T: AnalogRGBA)() const {
			return AnalogRGBA(this.redFP, this.greenFP, this.blueFP, this.alphaFP);
		}
	} else {
		// Missing alpha channel is the equivalent of 100% opacity
		auto opCast(T: AnalogRGBA)() const {
			return AnalogRGBA(this.redFP, this.greenFP, this.blueFP, 1.0);
		}
	}
}
