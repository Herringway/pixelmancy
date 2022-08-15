module pixelatrix.bpp3;

import pixelatrix.common;

/++
+ 3 bit per pixel tile format with palette. Each row has its bitplanes stored
+ adjacent to one another. Commonly used by the SNES.
+/
align(1) struct Intertwined3BPP {
	align(1):
	ubyte[8 * 3] raw;
	this(in ubyte[24] tile) @safe pure {
		raw = tile;
	}
	this(in ubyte[8][8] tile) @safe pure {
		foreach (rowID, row; tile) {
			foreach (colID, col; row) {
				this[rowID, colID] = col;
			}
		}
	}
	ubyte[8][8] pixelMatrix() const @safe pure
		out(result; result.isValidBitmap!3)
	{
		ubyte[8][8] output;
		foreach (x; 0..8) {
			foreach (y; 0..8) {
				output[x][y] = this[x, y];
			}
		}
		return output;
	}
	ubyte opIndex(size_t x, size_t y) const @safe pure {
		return getBit(raw[], (x * 2) * 8 + y) |
			(getBit(raw[], ((x * 2) + 1) * 8 + y) << 1) |
			(getBit(raw[], (x + 16) * 8 + y) << 2);
	}
	ubyte opIndexAssign(ubyte val, size_t x, size_t y) @safe pure {
		setBit(raw[], (x * 2) * 8 + y, val & 1);
		setBit(raw[], ((x * 2) + 1) * 8 + y, (val >> 1) & 1);
		setBit(raw[], (x + 16) * 8 + y, (val >> 2) & 1);
		return val;
	}
}
///
@safe pure unittest {
	import std.string : representation;
	const data = Intertwined3BPP(import("bpp3-sample1.bin").representation[0 .. 24]);
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
	assert(Intertwined3BPP(data.pixelMatrix()) == data);
}
