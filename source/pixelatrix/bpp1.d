module pixelatrix.bpp1;

import pixelatrix.common;

/++
+ 1 bit per pixel tile format. Commonly used by many platforms.
+
+ Params: data = an 8 byte array
+ Returns: a decoded 8x8 tile.
+/
align(1) struct Simple1BPP {
	align(1):
	ubyte[8] raw;
	this(in ubyte[8] tile) @safe pure {
		raw = tile;
	}
	this(in ubyte[8][8] tile) @safe pure {
		foreach (rowID, row; tile) {
			foreach (colID, col; row) {
				this[rowID, colID] = !!col;
			}
		}
	}
	ubyte[8][8] pixelMatrix() const @safe pure
		out(result; result.isValidBitmap!1)
	{
		ubyte[8][8] output;
		foreach (x; 0..8) {
			foreach (y; 0..8) {
				output[x][y] = this[x, y];
			}
		}
		return output;
	}
	bool opIndex(size_t x, size_t y) const @safe pure {
		return getBit(raw[], x * 8 + y);
	}
	bool opIndexAssign(bool val, size_t x, size_t y) @safe pure {
		setBit(raw[], x * 8 + y, val);
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
			assert(data[x, y] == finaldata[x][y]);
		}
	}
	Simple1BPP data2 = data;
	assert(data2[3, 3]);
	assert(!data2[3, 4]);
	data2[3, 4] = true;
	assert(data2[3, 4]);
	data2[3, 4] = false;
	assert(!data2[3, 4]);
	assert(data2 == data);
}
