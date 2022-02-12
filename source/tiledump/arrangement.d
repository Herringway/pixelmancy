module tiledump.arrangement;

import std.algorithm;
import std.bitmanip;
import std.exception;
import std.range;

enum ArrangementFormat {
	snes
}

struct Arrangement {
	TileAttributes[] tiles;
	size_t width;
	static Arrangement generate(ArrangementStyle style, size_t defaultSize, size_t width) @safe pure {
		size_t delegate(size_t) @safe pure dg;
		final switch (style) {
			case ArrangementStyle.horizontal:
				dg = (size_t x) => x;
				break;
			case ArrangementStyle.vertical:
				enforce(width > 0, "Must specify width!");
				dg = (size_t x) => ((x % width) * width) + (x/width);
				break;
		}
		return Arrangement(iota(0, defaultSize).map!(x => TileAttributes(dg(x), 0, false, false)).array, width > 0 ? width : defaultSize);
	}
}

enum ArrangementStyle {
	horizontal,
	vertical
}

align(1) struct SNESScreenTileArrangement {
	align(1):
	SNESTileAttributes[(256/8)*(224/8)] tiles;
	auto opCast(T: Arrangement)() const {
		auto arr = new TileAttributes[](tiles.length);
		foreach (idx, tile; tiles) {
			arr[idx] = cast(TileAttributes)tile;
		}
		return Arrangement(arr, 32);
	}
}
struct SNESTileArrangement {
	SNESTileAttributes[] tiles;
	size_t width;
	auto opCast(T: Arrangement)() const {
		auto arr = new TileAttributes[](tiles.length);
		foreach (idx, tile; tiles) {
			arr[idx] = cast(TileAttributes)tile;
		}
		return Arrangement(arr, width);
	}
}
align(1) struct SGBBorderTileArrangement {
	align(1):
	SNESTileAttributes[536] tiles;
	auto opCast(T: Arrangement)() const {
		auto arr = new TileAttributes[](32*28);
		ushort idxOffset;
		foreach (idx, tile; tiles) {
			const tilePosition = idx + idxOffset;
			arr[tilePosition] = cast(TileAttributes)tile;
			if ((tilePosition > 160) && (tilePosition < 736) && (tilePosition%32 == 5)) {
				idxOffset += 20;
			}
		}
		//arr[166 .. 186] = TileAttributes(0, 0);
		return Arrangement(arr, 32);
	}
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
	auto opCast(T: TileAttributes)() const {
		return TileAttributes(tile, palette, verticalFlip, horizontalFlip);
	}
}
struct TileAttributes {
	size_t tile;
	size_t palette;
	bool flipX;
	bool flipY;
}
