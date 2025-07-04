module pixelmancy.arrangement.arrangement;

import std.algorithm;
import std.bitmanip;
import std.exception;
import std.range;

import pixelmancy.util;

enum ArrangementFormat {
	snes
}

Array2D!T generateArrangement(T = TileAttributes)(ArrangementStyle style, size_t width, size_t height) @safe pure {
	size_t delegate(size_t) @safe pure dg;
	final switch (style) {
		case ArrangementStyle.rowMajor:
			dg = (size_t x) => x;
			break;
		case ArrangementStyle.columnMajor:
			enforce!PixelmancyException(width > 0, "Must specify width!");
			dg = (size_t x) => ((x % width) * width) + (x/width);
			break;
	}
	return Array2D!T(width, height, width, iota(0, width * height).map!(x => T(tile: cast(typeof(T.tile))dg(x))).array);
}

enum ArrangementStyle {
	rowMajor,
	columnMajor,
}

alias SNESScreenTileArrangement = StaticArray2D!(SNESTileAttributes, 32, 28);
alias SNESTileArrangement = Array2D!SNESTileAttributes;
alias ConsoleFullTileArrangement = StaticArray2D!(SNESTileAttributes, 32, 32);

alias SGBBorderTileArrangement = RowMajorFrameArrangement!(SNESTileAttributes, 32, 28, 20, 18);
align(1) struct RowMajorFrameArrangement(Tile, size_t inWidth, size_t inHeight, size_t innerWidth, size_t innerHeight) {
	align(1):
	enum width = inWidth;
	enum height = inHeight;
	enum borderWidth = (width - innerWidth) / 2;
	enum borderHeight = (height - innerHeight) / 2;
	Tile[width * height - innerWidth * innerHeight] tiles;
	this(const Array2D!Tile arrangement) @safe pure
		in(arrangement.width == width)
		in(arrangement.height == height)
	{
		ushort idxOffset;
		foreach (idx, tile; arrangement[]) {
			tiles[idxOffset] = tile;
			if ((idx > borderHeight * width) && (idx < (borderHeight + innerHeight) * width) && ((idx % width) > borderWidth - 1) && ((idx % width) < innerWidth + borderWidth)) {
				continue;
			}
			idxOffset++;
		}
	}
	auto ref opIndex(size_t x, size_t y) => tiles[y * width + x];
}

@safe pure unittest {
	auto arr = SGBBorderTileArrangement(generateArrangement!SNESTileAttributes(ArrangementStyle.rowMajor, 32, 28));
	assert(arr[2, 3].tile == 98);
}

align(1) struct SNESTileAttributes {
	align(1):
	mixin(bitfields!(
		ushort, "tile", 10,
		ubyte, "palette", 3,
		bool, "priority", 1,
		bool, "horizontalFlip", 1,
		bool, "verticalFlip", 1
	));
	this(ushort tile, ubyte palette = 0, bool priority = false, bool horizontalFlip = false, bool verticalFlip = false) @safe pure {
		this.tile = tile;
		this.palette = palette;
		this.priority = priority;
		this.horizontalFlip = horizontalFlip;
		this.verticalFlip = verticalFlip;
	}
	auto opCast(T: TileAttributes)() const {
		return TileAttributes(tile, palette, verticalFlip, horizontalFlip);
	}
	this(const TileAttributes attr) @safe pure {
		tile = attr.tile & 0x3FF;
		palette = attr.palette & 7;
		horizontalFlip = attr.horizontalFlip;
		verticalFlip = attr.verticalFlip;
	}
}
struct TileAttributes {
	size_t tile;
	size_t palette = 0;
	bool horizontalFlip = false;
	bool verticalFlip = false;
}
