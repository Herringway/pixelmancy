module pixelatrix.bpp1;

import pixelatrix.common;

/++
+ 1 bit per pixel tile format. Commonly used by many platforms.
+
+ Params: data = an 8 byte array
+ Returns: a decoded 8x8 tile.
+/
align(1) struct Simple1BPP {
	import std.format : format;
	enum width = 8;
	enum height = 8;
	enum bpp = 1;
	align(1):
	ubyte[8] raw;
	this(in ubyte[8] tile) @safe pure {
		raw = tile;
	}
	this(in ubyte[8][8] tile) @safe pure {
		foreach (rowID, row; tile) {
			foreach (colID, col; row) {
				this[colID, rowID] = !!col;
			}
		}
	}
	ubyte opIndex(size_t x, size_t y) const @safe pure
		in(x < width, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
		in(y < height, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
	{
		return getBit(raw[], y * 8 + x);
	}
	ubyte opIndexAssign(ubyte val, size_t x, size_t y) @safe pure
		in(x < width, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
		in(y < height, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
		in(val < 1 << bpp, "Value out of range")
	{
		setBit(raw[], y * 8 + x, !!val);
		return val;
	}
}
///
@safe pure unittest {
	import std.string : representation;
	const data = Simple1BPP(import("bpp1-sample1.bin").representation[0 .. 8]);
	const ubyte[8][8] finaldata = [
		[0, 1, 0, 0, 0, 0, 1, 0],
		[0, 0, 1, 0, 0, 0, 0, 0],
		[0, 0, 1, 1, 1, 0, 1, 1],
		[0, 1, 1, 1, 0, 0, 0, 1],
		[0, 1, 0, 1, 1, 1, 1, 1],
		[0, 1, 0, 1, 1, 1, 1, 1],
		[0, 0, 1, 0, 1, 1, 1, 1],
		[0, 0, 0, 1, 1, 1, 1, 0]];
	assert(data.pixelMatrix() == finaldata);
	assert(Simple1BPP(data.pixelMatrix()) == data);
	foreach (x; 0 .. 8) {
		foreach (y; 0 .. 8) {
			assert(data[x, y] == finaldata[y][x]);
		}
	}
	Simple1BPP data2 = data;
	assert(data2[3, 3] == 1);
	assert(data2[4, 3] == 0);
	assert(data2[3, 4] == 1);
	data2[4, 3] = 1;
	assert(data2[4, 3]);
	data2[4, 3] = 0;
	assert(data2[4, 3] == 0);
	assert(data2 == data);
}
