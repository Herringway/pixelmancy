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
	ubyte[8][8] pixelMatrix() const @safe pure
		out(result; result.isValidBitmap!1)
	{
		ubyte[8][8] output;
		foreach (x; 0..8) {
			foreach (y; 0..8) {
				output[x][7-y] = cast(ubyte)
					((raw[x]&(1<<y))>>y);
			}
		}
		return output;
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
}
