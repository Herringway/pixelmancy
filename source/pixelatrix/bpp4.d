module pixelatrix.bpp4;

import pixelatrix.common;

/++
+ 4 bit per pixel tile format with palette. Each row has its bitplanes stored
+ adjacent to one another. Commonly used by the SNES and PC Engine.
+/
align(1) struct Intertwined4BPP {
	align(1):
	ubyte[32] raw;
	this(in ubyte[32] tile) @safe pure {
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
		out(result; result.isValidBitmap!4)
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
			(getBit(raw[], ((x * 2) + 16) * 8 + y) << 2) |
			(getBit(raw[], ((x * 2) + 1 + 16) * 8 + y) << 3);
	}
	ubyte opIndexAssign(ubyte val, size_t x, size_t y) @safe pure {
		setBit(raw[], (x * 2) * 8 + y, val & 1);
		setBit(raw[], ((x * 2) + 1) * 8 + y, (val >> 1) & 1);
		setBit(raw[], ((x * 2) + 16) * 8 + y, (val >> 2) & 1);
		setBit(raw[], ((x * 2) + 1 + 16) * 8 + y, (val >> 3) & 1);
		return val;
	}
}
///
@safe pure unittest {
	import std.string : representation;
	const data = Intertwined4BPP(import("bpp4-sample1.bin").representation[0 .. 8 * 4]);
	const ubyte[8][8] finaldata = [
		[0x0, 0xF, 0x2, 0xE, 0xE, 0xE, 0xF, 0xA],
		[0x0, 0x0, 0xF, 0x6, 0xE, 0xE, 0xE, 0xE],
		[0x0, 0x0, 0xF, 0xF, 0xF, 0x8, 0xF, 0xF],
		[0x0, 0xF, 0xF, 0xF, 0x8, 0x8, 0x8, 0xF],
		[0x0, 0xF, 0x8, 0xF, 0x7, 0x7, 0xF, 0x7],
		[0x0, 0xF, 0x8, 0x7, 0x7, 0x7, 0xF, 0x7],
		[0x0, 0x0, 0xF, 0x8, 0x9, 0x9, 0x7, 0x7],
		[0x0, 0x0, 0x0, 0xF, 0x9, 0x9, 0xF, 0xA]
	];
	assert(data.pixelMatrix() == finaldata);
	assert(Intertwined4BPP(data.pixelMatrix()) == data);
}

/++
+ 4 bit per pixel tile format with palette. Each pixel is stored in linear order.
+ Commonly used by the GBA.
+/
align(1) struct GBA4BPP {
	align(1):
	ubyte[32] raw;
	this(in ubyte[32] tile) @safe pure {
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
		out(result; result.isValidBitmap!4)
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
		return (raw[x * 4 + y / 2] & (0xF << ((y & 1) * 4))) >> ((y & 1) * 4);
	}
	ubyte opIndexAssign(ubyte val, size_t x, size_t y) @safe pure {
		const mask = (0xF << ((~y & 1) * 4)) >> ((~y & 1) * 4);
		const newBit = (val & 0xF) << ((y & 1) * 4);
		raw[x * 4 + y / 2] = (raw[x * 4 + y / 2] & mask) | newBit;
		return val;
	}
}
///
@safe pure unittest {
	import std.string : representation;
	const data = GBA4BPP(import("bpp4-sample2.bin").representation[0 .. 8 * 4]);
	const ubyte[8][8] finaldata = [
		[0x0, 0x0, 0x3, 0xC, 0x5, 0xC, 0x5, 0x0],
		[0xE, 0xC, 0xD, 0xE, 0x6, 0x6, 0x6, 0x6],
		[0xC, 0xC, 0xD, 0x0, 0x0, 0x0, 0xB, 0x0],
		[0x3, 0x0, 0x3, 0x7, 0x0, 0x0, 0x3, 0x8],
		[0x0, 0x0, 0xC, 0x0, 0x0, 0x0, 0xD, 0x0],
		[0x0, 0x0, 0x8, 0x0, 0x1, 0x1, 0xF, 0x1],
		[0x8, 0x8, 0x9, 0x8, 0x0, 0x0, 0xE, 0x0],
		[0xC, 0xD, 0xC, 0xC, 0xE, 0x6, 0x6, 0xE]
	];
	assert(data.pixelMatrix() == finaldata);
	assert(GBA4BPP(data.pixelMatrix()) == data);
}
