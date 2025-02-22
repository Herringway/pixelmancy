module pixelmancy.tiles.bpp4;

import pixelmancy.tiles.common;

/++
+ 4 bit per pixel tile format with palette. Each row has its bitplanes stored
+ adjacent to one another. Commonly used by the SNES and PC Engine.
+/
alias Intertwined4BPP = Intertwined!4;
///
@safe pure unittest {
	import std.string : representation;
	const data = (cast(const(Intertwined4BPP)[])import("bpp4-sample1.bin").representation)[0];
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
	{
		Intertwined4BPP data2 = data;
		assert(data2[1, 0] == 15);
		data2[1, 0] = 1;
		assert(data2[1, 0] == 1);
	}
}

/++
+ 4 bit per pixel tile format with palette. Each pixel is stored in linear order.
+ Commonly used by the GBA.
+/
alias Packed4BPP = Packed!4;
///
@safe pure unittest {
	import std.string : representation;
	const data = (cast(const(Packed4BPP)[])import("bpp4-sample2.bin").representation)[0];
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
	{
		Packed4BPP data2;
		data2[0, 0] = 7;
		assert(data2.raw[0] == 7);
		data2[1, 0] = 15;
		assert(data2.raw[0] == 0xF7);
	}
	assert(data.pixelMatrix() == finaldata);
	{
		Packed4BPP data2 = data;
		assert(data2[0, 1] == 14);
		data2[0, 1] = 1;
		assert(data2[0, 1] == 1);
	}
}
