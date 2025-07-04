///
module pixelmancy.colours.utils;

import pixelmancy.colours.raw;

import std.algorithm;
import std.traits;

enum Channel {
	red,
	green,
	blue,
	alpha,
	luma,
	padding,
}

struct ChannelDefinition {
	Channel channel;
	ubyte bits;
}

private auto countTotalBits(ChannelDefinition[] channels) => channels.map!(x => x.bits).sum;

template generateChannelMixin(ChannelDefinition[] channels) {
	import std.conv : text;
	import std.meta : AliasSeq;
	alias generateChannelMixin = AliasSeq!();
	static foreach (channel; channels) {
		generateChannelMixin = AliasSeq!(generateChannelMixin, uint, channel.channel == Channel.padding ? "" : channel.channel.text, channel.bits);
	}
	enum totalBits = countTotalBits(channels);
	generateChannelMixin = AliasSeq!(generateChannelMixin, uint, "", ((totalBits + 7) / 8) * 8 - totalBits);
}

struct RGBGeneric(ChannelDefinition[] channels) {
	import std.bitmanip : bitfields;
	alias fields = generateChannelMixin!channels;
	static foreach (channel; channels) {
		static if (channel.channel == Channel.red) {
			enum redSize = channel.bits;
		} else static if (channel.channel == Channel.green) {
			enum greenSize = channel.bits;
		} else static if (channel.channel == Channel.blue) {
			enum blueSize = channel.bits;
		} else static if (channel.channel == Channel.alpha) {
			enum alphaSize = channel.bits;
		} else static if (channel.channel == Channel.padding) {
		} else {
			static assert(0, "Unsupported channel");
		}
	}
	void toString(S)(S sink) const {
		import std.format : formattedWrite;
		sink.formattedWrite("RGBA(%s, %s, %s, %s)", red, green, blue, alpha);
	}
	mixin colourCommon;
	mixin(bitfields!(fields));
}

struct RGBGeneric(T, Channel[] channels) {
	static foreach (channel; channels) {
		static if (channel == Channel.red) {
			T red;
			enum redSize = T.sizeof * 8;
		} else static if (channel == Channel.green) {
			T green;
			enum greenSize = T.sizeof * 8;
		} else static if (channel == Channel.blue) {
			T blue;
			enum blueSize = T.sizeof * 8;
		} else static if (channel == Channel.alpha) {
			T alpha;
			enum alphaSize = T.sizeof * 8;
		} else {
			static assert(0, "Unsupported channel");
		}
	}
	void toString(S)(S sink) const {
		import std.format : formattedWrite;
		sink.formattedWrite("RGBA(%s, %s, %s, %s)", red, green, blue, alpha);
	}
	size_t toHash() const @safe nothrow {
		return this.colourToInteger;
	}
	mixin colourCommon;
}

struct LumaChromaGeneric(ChannelDefinition[] channels) {
	import std.bitmanip : bitfields;
	alias fields = generateChannelMixin!channels;
	static foreach (channel; channels) {
		static if (channel.channel == Channel.luma) {
			enum lumaSize = channel.bits;
		} else static if (channel.channel == Channel.alpha) {
			enum alphaSize = channel.bits;
		} else static if (channel.channel == Channel.padding) {
		} else {
			static assert(0, "Unsupported channel");
		}
	}
	void toString(S)(S sink) const {
		import std.format : formattedWrite;
		sink.formattedWrite("RGBA(%s, %s, %s, %s)", red, green, blue, alpha);
	}
	mixin(bitfields!(fields));
}

struct LumaChromaGeneric(T, Channel[] channels) {
	static foreach (channel; channels) {
		static if (channel == Channel.luma) {
			T luma;
			enum lumaSize = T.sizeof * 8;
		} else static if (channel == Channel.alpha) {
			T alpha;
			enum alphaSize = T.sizeof * 8;
		} else {
			static assert(0, "Unsupported channel");
		}
	}
	void toString(S)(S sink) const {
		import std.format : formattedWrite;
		sink.formattedWrite("RGBA(%s, %s, %s, %s)", red, green, blue, alpha);
	}
}

template ClosestInteger(size_t bytes) {
	import std.meta : AliasSeq;
	static foreach (T; AliasSeq!(ubyte, ushort, uint, ulong)) {
		// find smallest integer type this'll fit in
		static if (!is(ClosestInteger) && (bytes <= T.sizeof)) {
			alias ClosestInteger = T;
		}
	}
}

static assert(is(ClosestInteger!1 == ubyte));
static assert(is(ClosestInteger!2 == ushort));
static assert(is(ClosestInteger!3 == uint));
static assert(is(ClosestInteger!4 == uint));
static assert(is(ClosestInteger!8 == ulong));

T read(T)(const ubyte[] input) if (isMutable!T)
	in(input.length == T.sizeof, "Mismatch between input buffer size and expected value size")
{
	union Result {
		ubyte[T.sizeof] raw;
		T val;
	}
	Result result;
	result.raw = input;
	return result.val;
}

ubyte[T.sizeof] asBytes(T)(T input) {
	union Result {
		T val;
		ubyte[T.sizeof] raw;
	}
	return Result(input).raw;
}

@safe pure unittest {
	import pixelmancy.colours.formats : BGR555;
	assert(BGR555(31, 31, 31).asBytes == [0xFF, 0x7F]);
	assert((const BGR555)(31, 31, 31).asBytes == [0xFF, 0x7F]);
	assert(BGR555(30, 31, 31).asBytes == [0xFE, 0x7F]);
}

enum isLumaChromaColourFormat(T) = hasLuma!T;
alias isLumaChromaColorFormat = isLumaChromaColourFormat;
enum isRGBColourFormat(T) = hasRed!T && hasGreen!T && hasBlue!T;
alias isRGBColorFormat = isRGBColourFormat;
enum isColourFormat(T) = isRGBColourFormat!T || isLumaChromaColourFormat!T;
alias isColorFormat = isRGBColourFormat;
enum hasRed(T) = __traits(hasMember, T, "redSize") && (T.redSize > 0);
enum hasGreen(T) = __traits(hasMember, T, "greenSize") && (T.greenSize > 0);
enum hasBlue(T) = __traits(hasMember, T, "blueSize") && (T.blueSize > 0);
enum hasAlpha(T) = __traits(hasMember, T, "alphaSize") && (T.alphaSize > 0);

enum hasLuma(T) = __traits(hasMember, T, "lumaSize") && (T.lumaSize > 0);
enum hasChroma(T) = false; //TODO

enum maxValue(ulong Bits) = (1<<Bits) - 1;

enum maxRed(T) = maxValue!(T.redSize);
enum maxGreen(T) = maxValue!(T.greenSize);
enum maxBlue(T) = maxValue!(T.blueSize);
enum maxAlpha(T) = maxValue!(T.alphaSize);

enum isDigital(T) = hasRed!T && hasGreen!T && hasBlue!T;

Precision redFP(Precision = double, Colour)(const Colour colour) if (hasRed!Colour) {
	return (cast(Precision)colour.red / maxRed!Colour);
}
void redFP(Precision, Colour)(ref Colour colour, Precision value) if (hasRed!Colour) {
	colour.red = cast(typeof(colour.red))(value * maxRed!Colour);
}

Precision greenFP(Precision = double, Colour)(const Colour colour) if (hasGreen!Colour) {
	return (cast(Precision)colour.green / maxGreen!Colour);
}
void greenFP(Precision, Colour)(ref Colour colour, Precision value) if (hasGreen!Colour) {
	colour.green = cast(typeof(colour.green))(value * maxGreen!Colour);
}

Precision blueFP(Precision = double, Colour)(const Colour colour) if (hasBlue!Colour) {
	return (cast(Precision)colour.blue / maxBlue!Colour);
}
void blueFP(Precision, Colour)(ref Colour colour, Precision value) if (hasBlue!Colour) {
	colour.blue = cast(typeof(colour.blue))(value * maxBlue!Colour);
}

Precision alphaFP(Precision = double, Colour)(const Colour colour) if (hasAlpha!Colour) {
	return (cast(Precision)colour.alpha / maxAlpha!Colour);
}
void alphaFP(Precision, Colour)(ref Colour colour, Precision value) if (hasAlpha!Colour) {
	colour.alpha = cast(typeof(colour.alpha))(value * maxAlpha!Colour);
}

@safe pure unittest {
	import pixelmancy.colours.formats : RGB24;
	import std.math : isClose;
	assert(RGB24(255, 128, 0).redFP() == 1.0);
	assert(RGB24(255, 128, 0).greenFP().isClose(0.5019607843137254));
	assert(RGB24(255, 128, 0).blueFP() == 0.0);
	assert(RGB24(0, 255, 128).redFP() == 0.0);
	assert(RGB24(0, 255, 128).greenFP() == 1.0);
	assert(RGB24(0, 255, 128).blueFP().isClose(0.5019607843137254));
	assert(RGB24(128, 0, 255).redFP().isClose(0.5019607843137254));
	assert(RGB24(128, 0, 255).greenFP() == 0.0);
	assert(RGB24(128, 0, 255).blueFP() == 1.0);
}

template LinearFormatOf(ColourFormat, Precision) {
	static if (hasAlpha!ColourFormat) {
		import pixelmancy.colours.formats : AnalogRGBA;
		alias LinearFormatOf = AnalogRGBA!Precision;
	} else {
		import pixelmancy.colours.formats : AnalogRGB;
		alias LinearFormatOf = AnalogRGB!Precision;
	}
}

LinearFormatOf!(Format, Precision) asLinearRGB(Precision = double, Format)(const Format colour) {
	static if (isDigital!Format) {
		const red = colour.redFP!Precision.toLinearRGB;
		const green = colour.greenFP!Precision.toLinearRGB;
		const blue = colour.blueFP!Precision.toLinearRGB;
		static if (hasAlpha!Format) {
			const alpha = colour.alphaFP!Precision.toLinearRGB;
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
		return LinearFormatOf!(Format, Precision)(red, green, blue, alpha);
	} else {
		return LinearFormatOf!(Format, Precision)(red, green, blue);
	}
}

private Precision toLinearRGB(Precision)(const Precision input) @safe pure @nogc nothrow {
	return input > 0.03928 ?
		((input + 0.055) / 1.055) ^^ 2.4 :
		input / 12.92 ;
}

private Precision gammaCorrect(Precision)(const Precision input, const Precision factor = 2.2) @safe pure @nogc nothrow {
	return input ^^ (1.0 / factor);
}

T channelConvert(T, size_t Size1, size_t Size2, Source)(Source val ) {
	static if (Size1 > Size2) {
		return cast(T)(val << (Size1 - Size2));
	} else static if (Size1 < Size2) {
		return cast(T)(val >> (Size2 - Size1));
	} else {
		return cast(T)val;
	}
}
mixin template colourCommon() {
	import pixelmancy.colours.formats : AnalogRGB, AnalogRGBA;
	this(uint red, uint green, uint blue) pure @safe
		in(red < (1<<redSize), "Red value out of range")
		in(green < (1<<greenSize), "Green value out of range")
		in(blue < (1<<blueSize), "Blue value out of range")
	{
		this.red = cast(typeof(this.red))red;
		this.green = cast(typeof(this.green))green;
		this.blue = cast(typeof(this.blue))blue;
		static if(hasAlpha!(typeof(this))) {
			this.alpha = maxAlpha!(typeof(this));
		}
	}
	this(Precision)(const AnalogRGB!Precision analog) pure @safe
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
		static if(hasAlpha!(typeof(this))) {
			this.alpha = maxAlpha!(typeof(this));
		}
	}
	T opCast(T: AnalogRGB!Precision, Precision)() const {
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
		this(Precision)(AnalogRGBA!Precision analog) pure @safe
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
		T opCast(T: AnalogRGBA!Precision, Precision)() const {
			return AnalogRGBA(this.redFP, this.greenFP, this.blueFP, this.alphaFP);
		}
	} else {
		// Missing alpha channel is the equivalent of 100% opacity
		T opCast(T: AnalogRGBA!Precision, Precision)() const {
			return AnalogRGBA(this.redFP, this.greenFP, this.blueFP, 1.0);
		}
	}
	bool opEquals(typeof(this) other) const @safe pure {
		bool result = true;
		static if (hasAlpha!(typeof(this))) {
			result &= this.alpha == other.alpha;
		}
		result &= this.red == other.red;
		result &= this.green == other.green;
		result &= this.blue == other.blue;
		return result;
	}
	/++ isSimilar compares two colours for similarity.
	+ Since precision isn't always equal, this function treats colour channels of greater precision as if they were
	+ ranges and tests if the channel of lesser precision falls within it. If channels have equal precision, this is
	+ identical to equality.
	+/
	bool isSimilar(Colour)(Colour other) const @safe pure if (isRGBColourFormat!Colour) {
		bool channelSimilar(size_t thisSize, size_t otherSize)(uint thisValue, uint otherValue) {
			static if (thisSize > otherSize) {
				thisValue >>= thisSize - otherSize;
			} else static if (thisSize < otherSize) {
				otherValue >>= otherSize - thisSize;
			}
			return thisValue == otherValue;
		}
		bool result = true;
		static if (hasAlpha!(typeof(this)) && hasAlpha!Colour) {
			result &= channelSimilar!(this.alphaSize, other.alphaSize)(this.alpha, other.alpha);
		}
		result &= channelSimilar!(this.redSize, other.redSize)(this.red, other.red);
		result &= channelSimilar!(this.greenSize, other.greenSize)(this.green, other.green);
		result &= channelSimilar!(this.blueSize, other.blueSize)(this.blue, other.blue);
		return result;
	}
	/++ isSimilar compares two colours for similarity.
	+/
	bool isSimilar(Colour)(Colour other, int tolerance) const @safe pure if (isRGBColourFormat!Colour) {
		bool channelSimilar(size_t thisSize, size_t otherSize)(uint thisValue, uint otherValue) {
			static if (thisSize > otherSize) {
				thisValue >>= thisSize - otherSize;
			} else static if (thisSize < otherSize) {
				otherValue >>= otherSize - thisSize;
			}
			return (cast(long)thisValue >= cast(long)otherValue - tolerance) && (cast(long)thisValue <= cast(long)otherValue + tolerance);
		}
		bool result = true;
		static if (hasAlpha!(typeof(this)) && hasAlpha!Colour) {
			result &= channelSimilar!(this.alphaSize, other.alphaSize)(this.alpha, other.alpha);
		}
		result &= channelSimilar!(this.redSize, other.redSize)(this.red, other.red);
		result &= channelSimilar!(this.greenSize, other.greenSize)(this.green, other.green);
		result &= channelSimilar!(this.blueSize, other.blueSize)(this.blue, other.blue);
		return result;
	}
}

@safe pure unittest {
	import pixelmancy.colours.formats : BGR555, RGB24, RGBA8888;
	assert(RGB24(255, 255, 255).isSimilar(RGB24(255, 255, 255)));
	assert(RGB24(255, 255, 255).isSimilar(RGBA8888(255, 255, 255)));
	assert(RGBA8888(255, 255, 255).isSimilar(RGB24(255, 255, 255)));
	assert(!RGBA8888(255, 255, 255, 72).isSimilar(RGBA8888(255, 255, 255, 0)));
	assert(RGB24(255, 255, 255).isSimilar(BGR555(31, 31, 31)));
	assert(RGB24(248, 248, 248).isSimilar(BGR555(31, 31, 31)));
	assert(RGB24(247, 58, 16).isSimilar(BGR555(30, 7, 2)));
	assert(!RGB24(247, 58, 16).isSimilar(BGR555(30, 31, 31)));
}
