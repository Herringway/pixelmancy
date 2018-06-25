module pixelatrix.bpp2;

/++
+ 2 bit per pixel tile format with palette. Consists of two bitplanes stored
+ one after the other. Commonly used by the NES.
+
+ Params: data = a 16 byte array
+ Returns: a decoded 8x8 tile.
+/
ubyte[][] toPixelMatrix(ubyte[] data) @safe pure in {
	assert(data.length == 8*2, "Data length mismatch");
} out(result) {
	foreach (row; result) {
		foreach (pixel; row) {
			assert(pixel < 4, "Pixel colour out of range");
		}
	}
} body {
	ubyte[][] output = new ubyte[][](8,8);
	foreach (x; 0..8) {
		foreach (y; 0..8) {
			output[x][7-y] = cast(ubyte)
				(((data[x]&(1<<y))>>y) +
				(((data[x+8]&(1<<y))>>y)<<1));
		}
	}
	return output;
}
///
@safe pure unittest {
	import std.string : representation;
	ubyte[] data = import("bpp2-sample1.bin").representation.dup;
	const ubyte[][] finaldata = [
		[0, 3, 2, 2, 2, 2, 3, 2],
		[0, 0, 3, 2, 2, 2, 2, 2],
		[0, 0, 3, 3, 3, 0, 3, 3],
		[0, 3, 3, 3, 0, 0, 0, 3],
		[0, 3, 0, 3, 3, 3, 3, 3],
		[0, 3, 0, 3, 3, 3, 3, 3],
		[0, 0, 3, 0, 1, 1, 3, 3],
		[0, 0, 0, 3, 1, 1, 3, 2]];
	assert(data.toPixelMatrix() == finaldata);
}
/++
+ 2 bit per pixel tile format with palette. Each row has its bitplanes stored
+ adjacent to one another. Commonly used by SNES and Gameboy.
+
+ Params: data = a 16 byte array
+ Returns: a decoded 8x8 tile.
+/
ubyte[][] toPixelMatrixIntertwined(ubyte[] data) @safe pure in {
	assert(data.length == 8*2, "Data length mismatch");
} out(result) {
	foreach (row; result) {
		foreach (pixel; row) {
			assert(pixel < 4, "Pixel colour out of range");
		}
	}
} body {
	ubyte[][] output = new ubyte[][](8,8);
	foreach (x; 0..8) {
		foreach (y; 0..8) {
			output[x][7-y] = cast(ubyte)
				(((data[x*2]&(1<<y))>>y) +
				(((data[x*2+1]&(1<<y))>>y)<<1));
		}
	}
	return output;
}
///
@safe pure unittest {
	import std.string : representation;
	ubyte[] data = import("bpp2-sample2.bin").representation.dup;
	const ubyte[][] finaldata = [
		[0, 3, 2, 2, 2, 2, 3, 2],
		[0, 0, 3, 2, 2, 2, 2, 2],
		[0, 0, 3, 3, 3, 0, 3, 3],
		[0, 3, 3, 3, 0, 0, 0, 3],
		[0, 3, 0, 3, 3, 3, 3, 3],
		[0, 3, 0, 3, 3, 3, 3, 3],
		[0, 0, 3, 0, 1, 1, 3, 3],
		[0, 0, 0, 3, 1, 1, 3, 2]];
	assert(data.toPixelMatrixIntertwined() == finaldata);
}