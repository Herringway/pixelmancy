module tilemagic.imageloader;

import std.algorithm.iteration;
import std.algorithm.searching;
import std.array;
import std.exception;
import std.stdio;

import justimages;
import siryul;

import tilemagic;
import tilemagic.util;

struct ParsedImage {
	ConsoleFullTileArrangement[1] arrangement;
	RGBA8888[] palette;
	Tile[] tiles;
}

ParsedImage loadImageFile(const(ubyte)[] image, TileFormat tileFormat, const Arrangement arrangement) @safe {
	ParsedImage result;
	auto img = cast(IndexedImage)readPngFromBytes(image);
	enforce(img, "Invalid image");
	if (((img.width % 8) != 0) || ((img.height % 8) != 0)) {
		throw new Exception("Error: image dimensions are not multiples of 8!");
	}
	const tileWidth = img.width / 8;
	const tileHeight = img.height / 8;
	Tile[] tiles;
	tiles.reserve(tileWidth * tileHeight);
	auto tileRows = array2D(img.data, img.width, img.height);
	foreach (th; 0 .. tileHeight) {
		foreach (w; 0 .. tileWidth) {
			auto tile = newTile(tileFormat);
			foreach (x; 0 .. 8) {
				foreach (y; 0 .. 8) {
					tile[x, y] = tileRows[w * 8 + x, th * 8 + y];
				}
			}
			tiles ~= tile;
		}
	}
	auto arrangement2D = array2D(result.arrangement[0].tiles, result.arrangement[0].width, result.arrangement[0].tiles.length / result.arrangement[0].width);
	const(ubyte)[][] seenTiles;
	ConsoleFullTileArrangement[1] arrangementToWrite;
	foreach (x, y, tileAttributes; array2D(arrangement.tiles, tileWidth, tileHeight)) {
		const data = getBytes(tiles[tileAttributes.tile]);
		const found = seenTiles.countUntil(data);
		if (found == -1) {
			result.tiles ~= tiles[tileAttributes.tile];
			seenTiles ~= data;
		}
		auto newTile = (found == -1) ? (seenTiles.length - 1) : found;
		if ((x < arrangement2D.width) && (y < arrangement2D.height)) {
			arrangement2D[x, y] = SNESTileAttributes(TileAttributes(newTile, tileAttributes.palette, tileAttributes.flipX, tileAttributes.flipY));
		}
	}
	result.palette = img.palette.map!(x => RGBA8888(x.r, x.g, x.b, x.a)).array;
	auto roundUp(size_t v) {
	    return (v / 16 + !!(v % 16)) * 16;
	}
	result.palette.length = roundUp(result.palette.length);
	return result;
}

@safe unittest {
	const result = loadImageFile(cast(immutable(ubyte)[])import("testsmile.png"), TileFormat.intertwined4BPP, Arrangement.generate(ArrangementStyle.horizontal, 32 * 32, 32));
}
