module pixelatrix.bpp8;

import pixelatrix.common;

/++
+ 8 bit per pixel tile format with palette. Each row has its bitplanes stored
+ adjacent to one another. Commonly used by the SNES.
+/
align(1) struct Linear8BPP {
	align(1):
	ubyte[8 * 8] raw;
	this(in ubyte[64] tile) @safe pure {
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
		out(result; result.isValidBitmap!8)
	{
		ubyte[8][8] output;
		foreach (x; 0..8) {
			output[x] = raw[x * 8 .. (x * 8) + 8];
		}
		return output;
	}
	ref inout(ubyte) opIndex(size_t x, size_t y) inout @safe pure return {
		return raw[x * 8 + y];
	}
}
///
@safe pure unittest {
	import std.string : representation;
	const data = Linear8BPP(import("bpp8-sample1.bin").representation[0 .. 8 * 8]);
	const ubyte[8][8] finaldata = [
		[0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF],
		[0xFE, 0xDC, 0xBA, 0x98, 0x76, 0x54, 0x32, 0x10],
		[0xEF, 0xCD, 0xAB, 0x89, 0x67, 0x45, 0x23, 0x01],
		[0x10, 0x32, 0x54, 0x76, 0x98, 0xBA, 0xDC, 0xFE],
		[0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF],
		[0xFE, 0xDC, 0xBA, 0x98, 0x76, 0x54, 0x32, 0x10],
		[0xEF, 0xCD, 0xAB, 0x89, 0x67, 0x45, 0x23, 0x01],
		[0x10, 0x32, 0x54, 0x76, 0x98, 0xBA, 0xDC, 0xFE]
	];
	assert(data.pixelMatrix() == finaldata);
	assert(Linear8BPP(data.pixelMatrix()) == data);
}
/++
+ 8 bit per pixel tile format with palette. Each row has its bitplanes stored
+ adjacent to one another. Commonly used by the SNES.
+/
align(1) struct Intertwined8BPP {
	align(1):
	ubyte[8 * 8] raw;
	this(in ubyte[64] tile) @safe pure {
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
		out(result; result.isValidBitmap!8)
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
			(getBit(raw[], ((x * 2) + 1 + 16) * 8 + y) << 3) |
			(getBit(raw[], ((x * 2) + 32) * 8 + y) << 4) |
			(getBit(raw[], ((x * 2) + 32 + 1) * 8 + y) << 5) |
			(getBit(raw[], ((x * 2) + 48) * 8 + y) << 6) |
			(getBit(raw[], ((x * 2) + 1 + 48) * 8 + y) << 7);
	}
	ubyte opIndexAssign(ubyte val, size_t x, size_t y) @safe pure {
		setBit(raw[], (x * 2) * 8 + y, val & 1);
		setBit(raw[], ((x * 2) + 1) * 8 + y, (val >> 1) & 1);
		setBit(raw[], ((x * 2) + 16) * 8 + y, (val >> 2) & 1);
		setBit(raw[], ((x * 2) + 1 + 16) * 8 + y, (val >> 3) & 1);
		setBit(raw[], ((x * 2) + 32) * 8 + y, (val >> 4) & 1);
		setBit(raw[], ((x * 2) + 1 + 32) * 8 + y, (val >> 5) & 1);
		setBit(raw[], ((x * 2) + 48) * 8 + y, (val >> 6) & 1);
		setBit(raw[], ((x * 2) + 1 + 48) * 8 + y, (val >> 7) & 1);
		return val;
	}
}
///
@safe pure unittest {
	import std.string : representation;
	const data = Intertwined8BPP(import("bpp8-sample2.bin").representation[0 .. 8 * 8]);
	const ubyte[8][8] finaldata = [
		[0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF],
		[0xFE, 0xDC, 0xBA, 0x98, 0x76, 0x54, 0x32, 0x10],
		[0xEF, 0xCD, 0xAB, 0x89, 0x67, 0x45, 0x23, 0x01],
		[0x10, 0x32, 0x54, 0x76, 0x98, 0xBA, 0xDC, 0xFE],
		[0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF],
		[0xFE, 0xDC, 0xBA, 0x98, 0x76, 0x54, 0x32, 0x10],
		[0xEF, 0xCD, 0xAB, 0x89, 0x67, 0x45, 0x23, 0x01],
		[0x10, 0x32, 0x54, 0x76, 0x98, 0xBA, 0xDC, 0xFE]
	];
	assert(data.pixelMatrix() == finaldata);
	assert(Intertwined8BPP(data.pixelMatrix()) == data);
}
