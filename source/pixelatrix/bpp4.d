module pixelatrix.bpp4;

import pixelatrix.common;
import siryul;

deprecated ubyte[8][8] toPixelMatrix(ubyte[] data) @safe pure in {
	assert(data.length == 8*4, "Data length mismatch");
} out(result) {
	foreach (row; result) {
		foreach (pixel; row) {
			assert(pixel < 16, "Pixel colour out of range");
		}
	}
} do {
	return Intertwined4BPP(data[0 .. 8 * 4]).pixelMatrix;
}
/++
+ 4 bit per pixel tile format with palette. Each row has its bitplanes stored
+ adjacent to one another. Commonly used by the SNES and PC Engine.
+/
align(1) struct Intertwined4BPP {
	align(1):
	ubyte[32] raw;
	@SerializationMethod
	string toBase64() const @safe {
		import std.base64 : Base64;
		return Base64.encode(raw[]);
	}
	ubyte[8][8] pixelMatrix() const @safe pure
		out(result; result.isValidBitmap!4)
	{
		ubyte[8][8] output;
		foreach (x; 0..8) {
			foreach (y; 0..8) {
				output[x][7-y] = cast(ubyte)
					(((raw[x*2]&(1<<y))>>y) +
					(((raw[x*2+1]&(1<<y))>>y)<<1) +
					(((raw[16 + x*2]&(1<<y))>>y)<<2) +
					(((raw[16 + x*2 + 1]&(1<<y))>>y)<<3));
			}
		}
		return output;
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
}

/++
+ 4 bit per pixel tile format with palette. Each pixel is stored in linear order.
+ Commonly used by the GBA.
+/
align(1) struct GBA4BPP {
	align(1):
	ubyte[32] raw;
	@SerializationMethod
	string toBase64() const @safe {
		import std.base64 : Base64;
		return Base64.encode(raw[]);
	}
	ubyte[8][8] pixelMatrix() const @safe pure
		out(result; result.isValidBitmap!4)
	{
		ubyte[8][8] output;
		foreach (i, b; raw) {
			output[i / 4][(i % 4) * 2] = b&0xF;
			output[i / 4][(i % 4) * 2 + 1] = (b&0xF0) >> 4;
		}
		return output;
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
}
