module pixelatrix.bpp4;

/++
+ 4 bit per pixel tile format with palette. Each row has its bitplanes stored
+ adjacent to one another. Commonly used by the SNES and PC Engine.
+
+ Params: data = a 32 byte array
+ Returns: a decoded 8x8 tile.
+/
ubyte[8][8] toPixelMatrix(ubyte[] data) @safe pure in {
	assert(data.length == 8*4, "Data length mismatch");
} out(result) {
	foreach (row; result) {
		foreach (pixel; row) {
			assert(pixel < 16, "Pixel colour out of range");
		}
	}
} body {
	ubyte[8][8] output;
	foreach (x; 0..8) {
		foreach (y; 0..8) {
			output[x][7-y] = cast(ubyte)
				(((data[x*2]&(1<<y))>>y) +
				(((data[x*2+1]&(1<<y))>>y)<<1) +
				(((data[16 + x*2]&(1<<y))>>y)<<2) +
				(((data[16 + x*2 + 1]&(1<<y))>>y)<<3));
		}
	}
	return output;
}
///
@safe pure unittest {
	import std.string : representation;
	ubyte[] data = import("bpp4-sample1.bin").representation.dup;
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
	assert(data.toPixelMatrix() == finaldata);
}