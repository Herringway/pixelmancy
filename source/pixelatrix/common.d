module pixelatrix.common;

package bool isValidBitmap(size_t size)(const ubyte[8][8] input) {
	foreach (row; input) {
		foreach (pixel; row) {
			if (pixel > (1<<size))  {
				return false;
			}
		}
	}
	return true;
}

package bool isValidBitmap(size_t size)(const ubyte[][] input) {
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

package void setBit(scope ubyte[] bytes, size_t index, bool value) @safe pure {
	const mask = ~(1 << (7 - (index % 8)));
	const newBit = value << (7 - (index % 8));
	bytes[index / 8] = cast(ubyte)((bytes[index / 8] & mask) | newBit);
}
package bool getBit(scope const ubyte[] bytes, size_t index) @safe pure {
	return !!(bytes[index / 8] & (1 << (7 - (index % 8))));
}


align(1) struct Intertwined(size_t inBPP) {
	enum width = 8;
	enum height = 8;
	enum bpp = inBPP;
	align(1):
	ubyte[(width * height * bpp) / 8] raw;
	ubyte opIndex(size_t x, size_t y) const @safe pure {
		ubyte result;
		static foreach (layer; 0 .. bpp) {
			result |= getBit(raw[], (y * 2 + ((layer & ~1) << 3) + (layer & 1)) * 8 + x) << layer;
		}
		return result;
	}
	ubyte opIndexAssign(ubyte val, size_t x, size_t y) @safe pure {
		static foreach (layer; 0 .. bpp) {
			setBit(raw[], ((y * 2) + ((layer & ~1) << 3) + (layer & 1)) * 8 + x, (val >> layer) & 1);
		}
		return val;
	}
}

align(1) struct Linear(size_t inBPP) {
	enum width = 8;
	enum height = 8;
	enum bpp = inBPP;
	import pixelatrix.bpp1 : Simple1BPP;
	align(1):
	Simple1BPP[bpp] planes;
	ubyte opIndex(size_t x, size_t y) const @safe pure {
		ubyte result;
		static foreach (layer; 0 .. bpp) {
			result |= planes[layer][x, y] << layer;
		}
		return result;
	}
	ubyte opIndexAssign(ubyte val, size_t x, size_t y) @safe pure
		in(val < 1 << bpp, "Value out of range")
	{
		static foreach (layer; 0 .. bpp) {
			planes[layer][x, y] = (val >> layer) & 1;
		}
		return val;
	}
	package ubyte[8 * bpp] raw() const @safe pure {
		return cast(ubyte[8 * bpp])planes[];
	}
}

align(1) struct Packed(size_t inBPP) {
	enum width = 8;
	enum height = 8;
	enum bpp = inBPP;
	align(1):
	ubyte[(width * height * bpp) / 8] raw;
	ubyte opIndex(size_t x, size_t y) const @safe pure {
		const pos = (y * width + x) / (8 / bpp);
		const shift = ((x & 1) * bpp) & 7;
		const mask = ((1 << bpp) - 1) << shift;
		return (raw[pos] & mask) >> shift;
	}
	ubyte opIndexAssign(ubyte val, size_t x, size_t y) @safe pure {
		const pos = (y * width + x) / (8 / bpp);
		const shift = ((x & 1) * bpp) & 7;
		const mask = ((1 << bpp) - 1) << shift;
		raw[pos] = (raw[pos] & ~mask) | cast(ubyte)((val & ((1 << bpp) - 1)) << shift);
		return val;
	}
}

auto pixelMatrix(Tile)(const Tile tile)
	out(result; result.isValidBitmap!(Tile.bpp))
{
	static if (__traits(compiles, Tile.width + 0) && __traits(compiles, Tile.height + 0)) {
		ubyte[Tile.width][Tile.height] output;
	} else {
		auto output = new ubyte[][](tile.width, tile.height);
	}
	foreach (x; 0 .. tile.width) {
		foreach (y; 0 .. tile.height) {
			output[y][x] = tile[x, y];
		}
	}
	return output;
}
