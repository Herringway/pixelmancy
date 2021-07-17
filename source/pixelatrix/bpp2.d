module pixelatrix.bpp2;

import pixelatrix.common;
import siryul;

/++
+ 2 bit per pixel tile format with palette. Consists of two bitplanes stored
+ one after the other. Commonly used by the NES.
+
+ Params: data = a 16 byte array
+ Returns: a decoded 8x8 tile.
+/
deprecated ubyte[8][8] toPixelMatrix(ubyte[] data) @safe pure
	in(data.length == 8 * 2, "Data length mismatch")
	out(result; result.isValidBitmap!2)
{
	return Linear2BPP(data[0 .. 8 * 2]).pixelMatrix;
}
align(1) struct Linear2BPP {
	align(1):
	ubyte[16] raw;
	@SerializationMethod
	string toBase64() const @safe {
		import std.base64 : Base64;
		return Base64.encode(raw[]);
	}
	ubyte[8][8] pixelMatrix() const @safe pure
		out(result; result.isValidBitmap!2)
	{
		ubyte[8][8] output;
		foreach (x; 0..8) {
			foreach (y; 0..8) {
				output[x][7-y] = cast(ubyte)
					(((raw[x]&(1<<y))>>y) +
					(((raw[x+8]&(1<<y))>>y)<<1));
			}
		}
		return output;
	}
}
///
@safe pure unittest {
	import std.string : representation;
	const data = Linear2BPP(import("bpp2-sample1.bin").representation[0 .. 8 * 2]);
	const ubyte[][] finaldata = [
		[0, 3, 2, 2, 2, 2, 3, 2],
		[0, 0, 3, 2, 2, 2, 2, 2],
		[0, 0, 3, 3, 3, 0, 3, 3],
		[0, 3, 3, 3, 0, 0, 0, 3],
		[0, 3, 0, 3, 3, 3, 3, 3],
		[0, 3, 0, 3, 3, 3, 3, 3],
		[0, 0, 3, 0, 1, 1, 3, 3],
		[0, 0, 0, 3, 1, 1, 3, 2]];
	assert(data.pixelMatrix() == finaldata);
}

/++
+ 2 bit per pixel tile format with palette. Each row has its bitplanes stored
+ adjacent to one another. Commonly used by SNES and Gameboy.
+
+ Params: data = a 16 byte array
+ Returns: a decoded 8x8 tile.
+/
deprecated ubyte[8][8] toPixelMatrixIntertwined(ubyte[] data) @safe pure
	in(data.length == 8 * 2, "Data length mismatch")
	out(result; result.isValidBitmap!2)
{
	return Intertwined2BPP(data[0 .. 8 * 2]).pixelMatrix;
}
align(1) struct Intertwined2BPP {
	align(1):
	ubyte[16] raw;
	@SerializationMethod
	string toBase64() const @safe {
		import std.base64 : Base64;
		return Base64.encode(raw[]);
	}
	ubyte[8][8] pixelMatrix() const @safe pure
		out(result; result.isValidBitmap!2)
	{
		ubyte[8][8] output;
		foreach (x; 0..8) {
			foreach (y; 0..8) {
				output[x][7-y] = cast(ubyte)
					(((raw[x*2]&(1<<y))>>y) +
					(((raw[x*2+1]&(1<<y))>>y)<<1));
			}
		}
		return output;
	}
}
///
@safe pure unittest {
	import std.string : representation;
	const data = Intertwined2BPP(import("bpp2-sample2.bin").representation[0 .. 8 * 2]);
	const ubyte[][] finaldata = [
		[0, 3, 2, 2, 2, 2, 3, 2],
		[0, 0, 3, 2, 2, 2, 2, 2],
		[0, 0, 3, 3, 3, 0, 3, 3],
		[0, 3, 3, 3, 0, 0, 0, 3],
		[0, 3, 0, 3, 3, 3, 3, 3],
		[0, 3, 0, 3, 3, 3, 3, 3],
		[0, 0, 3, 0, 1, 1, 3, 3],
		[0, 0, 0, 3, 1, 1, 3, 2]];
	assert(data.pixelMatrix() == finaldata);
}
