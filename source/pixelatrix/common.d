module pixelatrix.common;

bool isValidBitmap(size_t size)(const ubyte[8][8] input) {
	foreach (row; input) {
		foreach (pixel; row) {
			if (pixel > (1<<size))  {
				return false;
			}
		}
	}
	return true;
}

enum TileFormat {
	simple1BPP,
	linear2BPP,
	intertwined2BPP,
	intertwined3BPP,
	intertwined4BPP,
	gba4BPP,
	linear8BPP,
	intertwined8BPP,
}

size_t colours(const TileFormat format) @safe pure {
	final switch(format) {
		case TileFormat.simple1BPP:
			return 2^^1;
		case TileFormat.linear2BPP:
			return 2^^2;
		case TileFormat.intertwined2BPP:
			return 2^^2;
		case TileFormat.intertwined3BPP:
			return 2^^3;
		case TileFormat.intertwined4BPP:
			return 2^^4;
		case TileFormat.gba4BPP:
			return 2^^4;
		case TileFormat.intertwined8BPP:
			return 2^^8;
		case TileFormat.linear8BPP:
			return 2^^8;
	}
}

ubyte[8][8] pixelMatrix(const ubyte[] data, TileFormat format) @safe pure {
	import pixelatrix.bpp1 : Simple1BPP;
	import pixelatrix.bpp2 : Linear2BPP, Intertwined2BPP;
	import pixelatrix.bpp3 : Intertwined3BPP;
	import pixelatrix.bpp4 : Intertwined4BPP, GBA4BPP;
	import pixelatrix.bpp8 : Linear8BPP, Intertwined8BPP;
	static ubyte[8][8] fromFormat(T)(const ubyte[] data) {
		return T(data[0 .. T.sizeof]).pixelMatrix;
	}
	final switch (format) {
		case TileFormat.simple1BPP:
			return fromFormat!Simple1BPP(data);
		case TileFormat.linear2BPP:
			return fromFormat!Linear2BPP(data);
		case TileFormat.intertwined2BPP:
			return fromFormat!Intertwined2BPP(data);
		case TileFormat.intertwined3BPP:
			return fromFormat!Intertwined3BPP(data);
		case TileFormat.intertwined4BPP:
			return fromFormat!Intertwined4BPP(data);
		case TileFormat.intertwined8BPP:
			return fromFormat!Intertwined8BPP(data);
		case TileFormat.linear8BPP:
			return fromFormat!Linear8BPP(data);
		case TileFormat.gba4BPP:
			return fromFormat!GBA4BPP(data);
	}
}

ubyte[8][8][] pixelMatrices(const ubyte[] data, TileFormat format) @safe pure {
	import pixelatrix.bpp1 : Simple1BPP;
	import pixelatrix.bpp2 : Linear2BPP, Intertwined2BPP;
	import pixelatrix.bpp3 : Intertwined3BPP;
	import pixelatrix.bpp4 : Intertwined4BPP, GBA4BPP;
	import pixelatrix.bpp8 : Linear8BPP, Intertwined8BPP;
	static ubyte[8][8][] fromFormat(T)(const ubyte[] data) {
		auto output = new ubyte[8][8][](data.length / T.sizeof);
		foreach (idx, ref tile; output) {
			tile = T(data[idx * T.sizeof .. (idx + 1) * T.sizeof][0 .. T.sizeof]).pixelMatrix;
		}
		return output;
	}
	final switch (format) {
		case TileFormat.simple1BPP:
			return fromFormat!Simple1BPP(data);
		case TileFormat.linear2BPP:
			return fromFormat!Linear2BPP(data);
		case TileFormat.intertwined2BPP:
			return fromFormat!Intertwined2BPP(data);
		case TileFormat.intertwined3BPP:
			return fromFormat!Intertwined3BPP(data);
		case TileFormat.intertwined4BPP:
			return fromFormat!Intertwined4BPP(data);
		case TileFormat.intertwined8BPP:
			return fromFormat!Intertwined8BPP(data);
		case TileFormat.linear8BPP:
			return fromFormat!Linear8BPP(data);
		case TileFormat.gba4BPP:
			return fromFormat!GBA4BPP(data);
	}
}
