module pixelatrix.bpp3;

import pixelatrix.common;
import siryul;

/++
+ 3 bit per pixel tile format with palette. Each row has its bitplanes stored
+ adjacent to one another. Commonly used by the SNES.
+/
align(1) struct Intertwined3BPP {
	align(1):
	ubyte[8 * 3] raw;
	@SerializationMethod
	string toBase64() const @safe {
		import std.base64 : Base64;
		return Base64.encode(raw[]);
	}
	ubyte[8][8] pixelMatrix() const @safe pure
		out(result; result.isValidBitmap!3)
	{
		ubyte[8][8] output;
		foreach (x; 0..8) {
			foreach (y; 0..8) {
				output[x][7-y] = cast(ubyte)
					(((raw[x*2]&(1<<y))>>y) +
					(((raw[x*2+1]&(1<<y))>>y)<<1) +
					(((raw[16 + x]&(1<<y))>>y)<<2));
			}
		}
		return output;
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
}
