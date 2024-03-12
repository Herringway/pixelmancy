module pixelatrix.bpp2;

import pixelatrix.bpp1;
import pixelatrix.common;

/++
+ 2 bit per pixel tile format with palette. Consists of two bitplanes stored
+ one after the other. Commonly used by the NES.
+
+ Params: data = a 16 byte array
+ Returns: a decoded 8x8 tile.
+/
alias Linear2BPP = Linear!2;
///
@safe pure unittest {
	import std.string : representation;
	const data = (cast(const(Linear2BPP)[])import("bpp2-sample1.bin").representation)[0];
	const ubyte[][] finaldata = [
		[0, 3, 2, 2, 2, 2, 3, 2],
		[0, 0, 3, 2, 2, 2, 2, 2],
		[0, 0, 3, 3, 3, 0, 3, 3],
		[0, 3, 3, 3, 0, 0, 0, 3],
		[0, 3, 0, 3, 3, 3, 3, 3],
		[0, 3, 0, 3, 3, 3, 3, 3],
		[0, 0, 3, 0, 1, 1, 3, 3],
		[0, 0, 0, 3, 1, 1, 3, 2]];
	assert(data[1, 0] == 3);
	assert(data.pixelMatrix() == finaldata);
	Linear2BPP data2 = data;
	data2[0, 1] = 2;
	assert(data2[0, 1] == 2);
	{
		Linear2BPP data3;
		data3[1, 0] = 3;
		assert(data3[1, 0] == 3);
	}
}

/++
+ 2 bit per pixel tile format with palette. Each row has its bitplanes stored
+ adjacent to one another. Commonly used by SNES and Gameboy.
+
+ Params: data = a 16 byte array
+ Returns: a decoded 8x8 tile.
+/
alias Intertwined2BPP = Intertwined!2;
///
@safe pure unittest {
	import std.string : representation;
	const data = (cast(const(Intertwined2BPP)[])import("bpp2-sample2.bin").representation)[0];
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
	assert(data[1, 0] == 3);
	{
		Intertwined2BPP data2;
		data2[1, 0] = 3;
		assert(data2[1, 0] == 3);
	}
}
