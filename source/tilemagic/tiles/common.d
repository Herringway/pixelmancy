module tilemagic.tiles.common;

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
	packed4BPP,
	intertwined8BPP,
	packed8BPP,
}

size_t colours(const TileFormat format) @safe pure {
	final switch(format) {
		case TileFormat.simple1BPP:
			return 2^^1;
		case TileFormat.linear2BPP:
		case TileFormat.intertwined2BPP:
			return 2^^2;
		case TileFormat.intertwined3BPP:
			return 2^^3;
		case TileFormat.intertwined4BPP:
		case TileFormat.packed4BPP:
			return 2^^4;
		case TileFormat.intertwined8BPP:
		case TileFormat.packed8BPP:
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
	import std.format : format;
	enum width = 8;
	enum height = 8;
	enum bpp = inBPP;
	align(1):
	ubyte[(width * height * bpp) / 8] raw;
	ubyte opIndexBase(size_t x, size_t y) const @safe pure
		in(x < width, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
		in(y < height, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
	{
		ubyte result;
		static foreach (layer; 0 .. bpp) {
			result |= getBit(raw[], (y * 2 + ((layer & ~1) << 3) + (layer & 1)) * 8 + x) << layer;
		}
		return result;
	}
	ubyte opIndexAssignBase(ubyte val, size_t x, size_t y) @safe pure
		in(x < width, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
		in(y < height, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
		in(val < 1 << bpp, "Value out of range")
	{
		static foreach (layer; 0 .. bpp) {
			setBit(raw[], ((y * 2) + ((layer & ~1) << 3) + (layer & 1)) * 8 + x, (val >> layer) & 1);
		}
		return val;
	}
	mixin Common2DOps;
}

align(1) struct Linear(size_t inBPP) {
	import std.format : format;
	import tilemagic.tiles.bpp1 : Simple1BPP;
	enum width = 8;
	enum height = 8;
	enum bpp = inBPP;
	align(1):
	Simple1BPP[bpp] planes;
	ubyte opIndexBase(size_t x, size_t y) const @safe pure
		in(x < width, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
		in(y < height, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
	{
		ubyte result;
		static foreach (layer; 0 .. bpp) {
			result |= planes[layer][x, y] << layer;
		}
		return result;
	}
	ubyte opIndexAssignBase(ubyte val, size_t x, size_t y) @safe pure
		in(x < width, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
		in(y < height, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
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
	mixin Common2DOps;
}

align(1) struct Packed(size_t inBPP) {
	import std.format : format;
	enum width = 8;
	enum height = 8;
	enum bpp = inBPP;
	align(1):
	ubyte[(width * height * bpp) / 8] raw;
	ubyte opIndexBase(size_t x, size_t y) const @safe pure
		in(x < width, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
		in(y < height, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
	{
		const pos = (y * width + x) / (8 / bpp);
		const shift = ((x & 1) * bpp) & 7;
		const mask = ((1 << bpp) - 1) << shift;
		return (raw[pos] & mask) >> shift;
	}
	ubyte opIndexAssignBase(ubyte val, size_t x, size_t y) @safe pure
		in(x < width, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
		in(y < height, format!"index [%s, %s] is out of bounds for array of length [%s, %s]"(x, y, width, height))
		in(val < 1 << bpp, "Value out of range")
	{
		const pos = (y * width + x) / (8 / bpp);
		const shift = ((x & 1) * bpp) & 7;
		const mask = ((1 << bpp) - 1) << shift;
		raw[pos] = (raw[pos] & ~mask) | cast(ubyte)((val & ((1 << bpp) - 1)) << shift);
		return val;
	}
	mixin Common2DOps;
}

package mixin template Common2DOps() {
	import std.traits : Unqual;
	align:
	private alias _Tile = Unqual!(typeof(this));

	size_t[2] opSlice(size_t dimension)(size_t start, size_t end) const => (const TileView2D)(&this, 0, 0, width, height).opSlice!dimension(start, end);

	size_t opDollar(size_t dimension)() const => (const TileView2D)(&this, 0, 0, width, height).opDollar!dimension();

	inout(TileView2D) opIndex(size_t[2] r1, size_t[2] r2) inout => (inout(TileView2D)(&this, 0, 0, width, height)).opIndex(r1, r2);
	inout(TileView2D) opIndex(size_t[2] r1, size_t r2) inout => (inout(TileView2D)(&this, 0, 0, width, height)).opIndex(r1, r2);
	inout(TileView2D) opIndex(size_t r1, size_t[2] r2) inout => (inout(TileView2D)(&this, 0, 0, width, height)).opIndex(r1, r2);
	ubyte opIndex(size_t r1, size_t r2) inout @safe pure => opIndexBase(r1, r2);

	ubyte opIndexAssign(ubyte val) @safe pure => TileView2D(&this, 0, 0, width, height).opIndexAssign(val);
	ubyte opIndexAssign(ubyte val, size_t i, size_t j) @safe pure => opIndexAssignBase(val, i, j);
	ubyte opIndexAssign(ubyte val, size_t[2] i, size_t[2] j) @safe pure => TileView2D(&this, 0, 0, width, height).opIndexAssign(val, i, j);
	ubyte opIndexAssign(ubyte val, size_t[2] i, size_t j) @safe pure => TileView2D(&this, 0, 0, width, height).opIndexAssign(val, i, j);
	ubyte opIndexAssign(ubyte val, size_t i, size_t[2] j) @safe pure => TileView2D(&this, 0, 0, width, height).opIndexAssign(val, i, j);

	alias opApply = opApplyImpl!(int delegate(size_t x, size_t y, ubyte element));
	alias opApply = opApplyImplR!(int delegate(size_t x, size_t y, ref ubyte element));
	int opApplyImpl(DG)(scope DG dg) const => (const TileView2D)(&this, 0, 0, width, height).opApplyImpl(dg);
	int opApplyImplR(DG)(scope DG dg) => TileView2D(&this, 0, 0, width, height).opApplyImplR(dg);
	void toString(R)(ref R sink) const => (const TileView2D)(&this, 0, 0, width, height).toString(sink);
	private static struct TileView2D {
		import std.format : format;
		import std.traits : isMutable;
		private _Tile* tile;
		private size_t x, y, width, height;
		size_t[2] opSlice(size_t dimension)(size_t start, size_t end) const
			if (dimension >= 0 && dimension < 2)
			in(start >= 0 && end <= this.opDollar!dimension) => [start, end];
		size_t opDollar(size_t dimension : 0)() const => width;
		size_t opDollar(size_t dimension : 1)() const => height;
		inout(TileView2D) opIndex(size_t[2] r1, size_t[2] r2) inout
			in(r1[0] <= width, format!"slice [%s..%s] extends beyond array of width %s"(r1[0], r1[1], width))
			in(r1[1] <= width, format!"slice [%s..%s] extends beyond array of width %s"(r1[0], r1[1], width))
			in(r2[0] <= height, format!"slice [%s..%s] extends beyond array of height %s"(r2[0], r2[1], height))
			in(r2[1] <= height, format!"slice [%s..%s] extends beyond array of height %s"(r2[0], r2[1], height))
		{
			return (inout TileView2D)(tile, x + r1[0], y + r2[0], r1[1] - r1[0], r2[1] - r2[0]);
		}
		inout(TileView2D) opIndex(size_t[2] r1, size_t r2) inout => opIndex(r1, [r2, r2 + 1]);
		inout(TileView2D) opIndex(size_t r1, size_t[2] r2) inout => opIndex([r1, r1 + 1], r2);
		ubyte opIndex(size_t x, size_t y) inout => (*tile)[this.x + x, this.y + y];
		inout(TileView2D) opIndex() inout => this;
		ubyte opIndexAssign(ubyte value) @safe pure {
			foreach (destX; x .. x + width) {
				foreach (destY; y .. y + height) {
					this[destX, destY] = value;
				}
			}
			return value;
		}
		ubyte opIndexAssign(ubyte value, size_t i, size_t j) @safe pure {
			(*tile)[x + i, y + j] = value;
			return value;
		}
		ubyte opIndexAssign(ubyte elem, size_t[2] i, size_t[2] j) @safe pure {
			foreach (row; j[0] .. j[1]) {
				foreach (column; i[0] .. i[1]) {
					this[x + column, y + row] = elem;
				}
			}
			return elem;
		}
		ubyte opIndexAssign(ubyte elem, size_t i, size_t[2] j) @safe pure {
			opIndexAssign(elem, [i, i+1], j);
			return elem;
		}
		ubyte opIndexAssign(ubyte elem, size_t[2] i, size_t j) @safe pure {
			opIndexAssign(elem, i, [j, j+1]);
			return elem;
		}
		void toString(R)(ref R sink) const {
			import std.format : formattedWrite;
			import std.range : put;
			foreach (row; y .. y + height) {
				put(sink, '[');
				foreach (column; x .. x + width) {
					sink.formattedWrite!"%02X"(this[column, row]);
					if (column < x + width - 1) {
						put(sink, ", ");
					}
				}
				put(sink, ']');
				if (row < y + height - 1) {
					put(sink, '\n');
				}
			}
		}
		alias opApply = opApplyImpl!(int delegate(size_t x, size_t y, ubyte element));
		int opApplyImpl(DG)(scope DG dg) const {
			foreach (iterY; 0 .. height) {
				foreach (iterX; 0 .. width) {
					auto result = dg(iterX, iterY, this[iterX, iterY]);
					if (result) {
						return result;
					}
				}
			}
			return 0;
		}
		alias opApply = opApplyImplR!(int delegate(size_t x, size_t y, ref ubyte element));
		int opApplyImplR(DG)(scope DG dg) {
			foreach (iterY; 0 .. height) {
				foreach (iterX; 0 .. width) {
					auto initial = this[iterX, iterY];
					auto result = dg(iterX, iterY, initial);
					this[iterX, iterY] = initial;
					if (result) {
						return result;
					}
				}
			}
			return 0;
		}
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

interface Tile {
	enum width = 8;
	enum height = 8;
	ubyte bpp() const @safe pure;
	size_t size() const @safe pure;
	int opApply(int delegate(size_t x, size_t y, ubyte element)) const;
	int opApply(int delegate(size_t x, size_t y, ref ubyte element));
	uint opIndex(size_t x, size_t y) const @safe pure;
	uint opIndexAssign(uint val, size_t x, size_t y) @safe pure;
	const(ubyte)[] raw() const @safe pure;
}

class TileClass(T) : Tile {
	T[1] tile;
	this() @safe pure {}
	this(const ubyte[T.sizeof] data) @safe pure {
		tile = (cast(const(T)[])(data[]))[0];
	}
	ubyte bpp() const @safe pure {
		return T.bpp;
	}
	size_t size() const @safe pure {
		return T.sizeof;
	}
	uint opIndex(size_t x, size_t y) const @safe pure {
		return tile[0][x, y];
	}
	uint opIndexAssign(uint val, size_t x, size_t y) @safe pure {
		return tile[0][x, y] = cast(ubyte)val;
	}
	const(ubyte)[] raw() const @safe pure {
		return cast(const(ubyte)[])tile;
	}
	int opApply(int delegate(size_t x, size_t y, ubyte element) dg) const {
		return tile[0].opApply(dg);
	}
	int opApply(int delegate(size_t x, size_t y, ref ubyte element) dg) {
		return tile[0].opApply(dg);
	}
}

Tile newTile(TileFormat format) @safe pure {
	import tilemagic.tiles.bpp1 : Simple1BPP;
	import tilemagic.tiles.bpp2 : Linear2BPP, Intertwined2BPP;
	import tilemagic.tiles.bpp3 : Intertwined3BPP;
	import tilemagic.tiles.bpp4 : Intertwined4BPP, Packed4BPP;
	import tilemagic.tiles.bpp8 : Intertwined8BPP, Packed8BPP;
	final switch (format) {
		case TileFormat.simple1BPP:
			return new TileClass!Simple1BPP();
		case TileFormat.linear2BPP:
			return new TileClass!Linear2BPP();
		case TileFormat.intertwined2BPP:
			return new TileClass!Intertwined2BPP();
		case TileFormat.intertwined3BPP:
			return new TileClass!Intertwined3BPP();
		case TileFormat.intertwined4BPP:
			return new TileClass!Intertwined4BPP();
		case TileFormat.packed4BPP:
			return new TileClass!Packed4BPP();
		case TileFormat.intertwined8BPP:
			return new TileClass!Intertwined8BPP();
		case TileFormat.packed8BPP:
			return new TileClass!Packed8BPP();
	}
}

Tile getTile(const ubyte[] data, TileFormat format) @safe pure {
	import tilemagic.tiles.bpp1 : Simple1BPP;
	import tilemagic.tiles.bpp2 : Linear2BPP, Intertwined2BPP;
	import tilemagic.tiles.bpp3 : Intertwined3BPP;
	import tilemagic.tiles.bpp4 : Intertwined4BPP, Packed4BPP;
	import tilemagic.tiles.bpp8 : Intertwined8BPP, Packed8BPP;
	static Tile getType(T)(const ubyte[] data) {
		return new TileClass!T(data[0 .. T.sizeof]);
	}
	final switch (format) {
		case TileFormat.simple1BPP:
			return getType!Simple1BPP(data);
		case TileFormat.linear2BPP:
			return getType!Linear2BPP(data);
		case TileFormat.intertwined2BPP:
			return getType!Intertwined2BPP(data);
		case TileFormat.intertwined3BPP:
			return getType!Intertwined3BPP(data);
		case TileFormat.intertwined4BPP:
			return getType!Intertwined4BPP(data);
		case TileFormat.packed4BPP:
			return getType!Packed4BPP(data);
		case TileFormat.intertwined8BPP:
			return getType!Intertwined8BPP(data);
		case TileFormat.packed8BPP:
			return getType!Packed8BPP(data);
	}
}

Tile[] getTiles(const ubyte[] data, TileFormat format) @safe pure {
	import tilemagic.tiles.bpp1 : Simple1BPP;
	import tilemagic.tiles.bpp2 : Linear2BPP, Intertwined2BPP;
	import tilemagic.tiles.bpp3 : Intertwined3BPP;
	import tilemagic.tiles.bpp4 : Intertwined4BPP, Packed4BPP;
	import tilemagic.tiles.bpp8 : Intertwined8BPP, Packed8BPP;
	static Tile[] getType(T)(const ubyte[] data)
		in((data.length % T.sizeof) == 0, "Provided data is not an even multiple of the tile size")
	{
		Tile[] tiles;
		tiles.reserve(data.length / T.sizeof);
		foreach (i; 0 .. data.length / T.sizeof) {
			tiles ~= new TileClass!T(data[i * T.sizeof .. (i + 1) * T.sizeof][0 .. T.sizeof]);
		}
		return tiles;
	}
	final switch (format) {
		case TileFormat.simple1BPP:
			return getType!Simple1BPP(data);
		case TileFormat.linear2BPP:
			return getType!Linear2BPP(data);
		case TileFormat.intertwined2BPP:
			return getType!Intertwined2BPP(data);
		case TileFormat.intertwined3BPP:
			return getType!Intertwined3BPP(data);
		case TileFormat.intertwined4BPP:
			return getType!Intertwined4BPP(data);
		case TileFormat.packed4BPP:
			return getType!Packed4BPP(data);
		case TileFormat.intertwined8BPP:
			return getType!Intertwined8BPP(data);
		case TileFormat.packed8BPP:
			return getType!Packed8BPP(data);
	}
}

void getBytes(const Tile tile, scope void delegate(scope const(ubyte)[]) @safe pure sink) @safe pure {
	sink(tile.raw);
}

void getBytes(const Tile[] tiles, scope void delegate(scope const(ubyte)[]) @safe pure sink) @safe pure {
	foreach (tile; tiles) {
		sink(tile.raw);
	}
}

ubyte[] getBytes(const Tile tile) @safe pure {
	ubyte[] result;
	getBytes(tile, (data) { result ~= data; });
	return result;
}

ubyte[] getBytes(const Tile[] tiles) @safe pure {
	ubyte[] result;
	getBytes(tiles, (data) { result ~= data; });
	return result;
}

@safe pure unittest {
	ubyte[] data = new ubyte[](128);
	assert(getBytes(getTiles(data, TileFormat.packed4BPP)) == data);
}
