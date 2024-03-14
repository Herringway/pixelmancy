module pixelatrix.bpp3;

import pixelatrix.bpp1;
import pixelatrix.common;

import std.format;

/++
+ 3 bit per pixel tile format with palette. Each row has its bitplanes stored
+ adjacent to one another. Commonly used by the SNES.
+/
align(1) struct Intertwined3BPP {
	enum width = 8;
	enum height = 8;
	enum bpp = 3;
	align(1):
	Intertwined!2 planes01;
	Simple1BPP plane2;
	ubyte opIndex(size_t x, size_t y) const @safe pure
		in(x < width, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
		in(y < height, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
	{
		return cast(ubyte)(planes01[x, y] + (plane2[x, y] << 2));
	}
	ubyte opIndexAssign(ubyte val, size_t x, size_t y) @safe pure
		in(x < width, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
		in(y < height, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
		in(val < 1 << bpp, "Value out of range")
	{
		planes01[x, y] = val & 3;
		plane2[x, y] = (val & 4) >> 2;
		return val;
	}
}
///
@safe pure unittest {
	import std.string : representation;
	const data = (cast(const(Intertwined3BPP)[])import("bpp3-sample1.bin").representation)[0];
	const ubyte[8][8] finaldata = [
		[0x0, 0x7, 0x2, 0x6, 0x6, 0x6, 0x7, 0x2],
		[0x0, 0x0, 0x7, 0x6, 0x6, 0x6, 0x6, 0x6],
		[0x0, 0x0, 0x7, 0x7, 0x7, 0x0, 0x7, 0x7],
		[0x0, 0x7, 0x7, 0x7, 0x0, 0x0, 0x0, 0x7],
		[0x0, 0x7, 0x0, 0x7, 0x7, 0x7, 0x7, 0x7],
		[0x0, 0x7, 0x0, 0x7, 0x7, 0x7, 0x7, 0x7],
		[0x0, 0x0, 0x7, 0x0, 0x1, 0x1, 0x7, 0x7],
		[0x0, 0x0, 0x0, 0x7, 0x1, 0x1, 0x7, 0x2]
	];
	assert(data.pixelMatrix() == finaldata);
	assert(data[1, 0] == 7);
	{
		Intertwined3BPP data2 = data;
		assert(data2[0, 1] == 0);
		data2[0, 1] = 6;
		assert(data2[0, 1] == 6);
	}
}
