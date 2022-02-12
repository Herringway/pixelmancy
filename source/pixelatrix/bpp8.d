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
				raw[rowID * row.length + colID] = col;
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
				raw[rowID * 2] |= cast(ubyte)((col & 1) << (row.length - 1 - colID));
				raw[(rowID * 2) + 1] |= cast(ubyte)(((col & 2) >> 1) << (row.length - 1 - colID));
				raw[16 + (rowID * 2)] |= cast(ubyte)(((col & 4) >> 2) << (row.length - 1 - colID));
				raw[16 + (rowID * 2) + 1] |= cast(ubyte)(((col & 8) >> 3) << (row.length - 1 - colID));
				raw[32 + (rowID * 2)] |= cast(ubyte)(((col & 16) >> 4) << (row.length - 1 - colID));
				raw[32 + (rowID * 2) + 1] |= cast(ubyte)(((col & 32) >> 5) << (row.length - 1 - colID));
				raw[48 + (rowID * 2)] |= cast(ubyte)(((col & 64) >> 6) << (row.length - 1 - colID));
				raw[48 + (rowID * 2) + 1] |= cast(ubyte)(((col & 128) >> 7) << (row.length - 1 - colID));
			}
		}
	}
	ubyte[8][8] pixelMatrix() const @safe pure
		out(result; result.isValidBitmap!8)
	{
		ubyte[8][8] output;
		foreach (x; 0..8) {
			foreach (y; 0..8) {
				output[x][7-y] = cast(ubyte)
					(((raw[(8 * 0) + x*2]&(1<<y))>>y) +
					(((raw[(8 * 0) + x*2+1]&(1<<y))>>y)<<1) +
					(((raw[(8 * 2) + x*2]&(1<<y))>>y)<<2) +
					(((raw[(8 * 2) + x*2 + 1]&(1<<y))>>y)<<3) +
					(((raw[(8 * 4) + x*2]&(1<<y))>>y)<<4) +
					(((raw[(8 * 4) + x*2 + 1]&(1<<y))>>y)<<5) +
					(((raw[(8 * 6) + x*2]&(1<<y))>>y)<<6) +
					(((raw[(8 * 6) + x*2 + 1]&(1<<y))>>y)<<7)
				);
			}
		}
		return output;
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
