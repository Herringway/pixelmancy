module tilemagic.imagesaver;

import std.algorithm;
import std.traits;

import tilemagic.arrangement;
import tilemagic.colours;
import tilemagic.util;

struct PaletteCoords {
	uint colour;
	uint palette;
}

Array2D!PaletteCoords toPaletteCoords(Tile, T)(const Tile[] tiles, const Array2D!T tilemap) {
	const width = tilemap.width;
	const imageWidth = tiles[0].width * width;
	const imageHeight = tiles[0].height * tilemap.height;
	auto result = Array2D!PaletteCoords(imageWidth, imageHeight);
	foreach (size_t tileX, size_t tileY, tileattrs; tilemap) {
		const pixels = tiles[tileattrs.tile % tiles.length];
		const baseX = tileX * tiles[0].height;
		const baseY = tileY * tiles[0].width;
		foreach (size_t tileX, size_t tileY, pixel; pixels) {
			const x = baseX + (tileattrs.horizontalFlip ? ((tiles[0].width - 1) - tileX) : tileX);
			const y = baseY + (tileattrs.verticalFlip ? ((tiles[0].height - 1) - tileY) : tileY);
			result[x, y] = PaletteCoords(pixel, cast(uint)tileattrs.palette);
		}
	}
	return result;
}

Array2D!(Unqual!Colour) toTrueColour(Colour)(const Array2D!PaletteCoords paletteCoords, const Array2D!Colour palettes) {
	return toTrueColour!(Unqual!Colour, Colour)(paletteCoords, palettes);
}

Array2D!(TargetColour) toTrueColour(TargetColour, Colour)(const Array2D!PaletteCoords paletteCoords, const Array2D!Colour palettes) {
	auto result = Array2D!TargetColour(paletteCoords.width, paletteCoords.height);
	foreach (x, y, colour; paletteCoords) {
		result[x, y] = palettes[colour.colour, colour.palette].convert!TargetColour;
	}
	return result;
}

@safe pure unittest {
	import tilemagic.tiles.bpp4 : Intertwined4BPP;
	const tiles = cast(immutable(Intertwined4BPP)[])import("imagesaver_test.bpp4");
	const tilemap = array2D(cast(immutable(SNESTileAttributes)[])import("imagesaver_test.arr"), 2, 2);
	const palettePixels = toPaletteCoords(tiles, tilemap[0 .. $, 0 .. $]);
	alias PC = PaletteCoords;
	assert(palettePixels == Array2D!PaletteCoords(16, 16, [
		PC(7, 0), PC(0, 0), PC(4, 0), PC(0, 0), PC(7, 0), PC(2, 0), PC(10, 0), PC(2, 0), PC(10, 1), PC(0, 1), PC(12, 1), PC(11, 1), PC(10, 1), PC(10, 1), PC(8, 1), PC(7, 1),
		PC(4, 0), PC(3, 0), PC(15, 0), PC(0, 0), PC(13, 0), PC(4, 0), PC(13, 0), PC(4, 0), PC(14, 1), PC(12, 1), PC(4, 1), PC(11, 1), PC(1, 1), PC(0, 1), PC(0, 1), PC(4, 1),
		PC(6, 0), PC(6, 0), PC(14, 0), PC(13, 0), PC(6, 0), PC(0, 0), PC(7, 0), PC(8, 0), PC(6, 1), PC(5, 1), PC(0, 1), PC(3, 1), PC(4, 1), PC(10, 1), PC(0, 1), PC(9, 1),
		PC(1, 0), PC(0, 0), PC(1, 0), PC(14, 0), PC(4, 0), PC(15, 0), PC(8, 0), PC(15, 0), PC(10, 1), PC(5, 1), PC(7, 1), PC(12, 1), PC(8, 1), PC(15, 1), PC(9, 1), PC(12, 1),
		PC(0, 0), PC(4, 0), PC(7, 0), PC(3, 0), PC(0, 0), PC(10, 0), PC(13, 0), PC(9, 0), PC(2, 1), PC(9, 1), PC(14, 1), PC(10, 1), PC(7, 1), PC(6, 1), PC(15, 1), PC(9, 1),
		PC(9, 0), PC(0, 0), PC(12, 0), PC(13, 0), PC(7, 0), PC(2, 0), PC(0, 0), PC(2, 0), PC(13, 1), PC(3, 1), PC(3, 1), PC(13, 1), PC(10, 1), PC(1, 1), PC(0, 1), PC(0, 1),
		PC(1, 0), PC(8, 0), PC(8, 0), PC(14, 0), PC(12, 0), PC(3, 0), PC(4, 0), PC(9, 0), PC(10, 1), PC(1, 1), PC(15, 1), PC(3, 1), PC(9, 1), PC(6, 1), PC(14, 1), PC(8, 1),
		PC(5, 0), PC(0, 0), PC(11, 0), PC(7, 0), PC(7, 0), PC(4, 0), PC(9, 0), PC(4, 0), PC(8, 1), PC(3, 1), PC(6, 1), PC(4, 1), PC(14, 1), PC(11, 1), PC(14, 1), PC(13, 1),
		PC(10, 2), PC(1, 2), PC(10, 2), PC(6, 2), PC(6, 2), PC(2, 2), PC(15, 2), PC(10, 2), PC(6, 3), PC(10, 3), PC(10, 3), PC(10, 3), PC(1, 3), PC(11, 3), PC(9, 3), PC(12, 3),
		PC(3, 2), PC(1, 2), PC(7, 2), PC(11, 2), PC(3, 2), PC(7, 2), PC(12, 2), PC(15, 2), PC(6, 3), PC(7, 3), PC(2, 3), PC(15, 3), PC(5, 3), PC(9, 3), PC(2, 3), PC(4, 3),
		PC(11, 2), PC(15, 2), PC(1, 2), PC(11, 2), PC(1, 2), PC(6, 2), PC(12, 2), PC(15, 2), PC(8, 3), PC(0, 3), PC(7, 3), PC(10, 3), PC(6, 3), PC(6, 3), PC(1, 3), PC(1, 3),
		PC(1, 2), PC(11, 2), PC(4, 2), PC(3, 2), PC(5, 2), PC(7, 2), PC(10, 2), PC(14, 2), PC(0, 3), PC(1, 3), PC(8, 3), PC(13, 3), PC(0, 3), PC(8, 3), PC(2, 3), PC(4, 3),
		PC(15, 2), PC(1, 2), PC(14, 2), PC(8, 2), PC(5, 2), PC(4, 2), PC(3, 2), PC(4, 2), PC(4, 3), PC(14, 3), PC(8, 3), PC(6, 3), PC(9, 3), PC(14, 3), PC(11, 3), PC(13, 3),
		PC(14, 2), PC(0, 2), PC(3, 2), PC(14, 2), PC(10, 2), PC(1, 2), PC(1, 2), PC(13, 2), PC(3, 3), PC(2, 3), PC(15, 3), PC(15, 3), PC(3, 3), PC(5, 3), PC(0, 3), PC(8, 3),
		PC(3, 2), PC(3, 2), PC(10, 2), PC(4, 2), PC(5, 2), PC(15, 2), PC(7, 2), PC(8, 2), PC(3, 3), PC(2, 3), PC(9, 3), PC(2, 3), PC(15, 3), PC(1, 3), PC(11, 3), PC(0, 3),
		PC(14, 2), PC(14, 2), PC(15, 2), PC(12, 2), PC(12, 2), PC(6, 2), PC(8, 2), PC(13, 2), PC(6, 3), PC(8, 3), PC(13, 3), PC(15, 3), PC(7, 3), PC(15, 3), PC(14, 3), PC(15, 3)
	]));
	const palettes = array2D(cast(immutable(BGR555)[])import("imagesaver_test.pal"), 16, 4);
	const pixels = palettePixels.toTrueColour(palettes);
	assert(pixels == (immutable Array2D!BGR555)(16, 16, [
		palettes[7, 0], palettes[0, 0], palettes[4, 0], palettes[0, 0], palettes[7, 0], palettes[2, 0], palettes[10, 0], palettes[2, 0], palettes[10, 1], palettes[0, 1], palettes[12, 1], palettes[11, 1], palettes[10, 1], palettes[10, 1], palettes[8, 1], palettes[7, 1],
		palettes[4, 0], palettes[3, 0], palettes[15, 0], palettes[0, 0], palettes[13, 0], palettes[4, 0], palettes[13, 0], palettes[4, 0], palettes[14, 1], palettes[12, 1], palettes[4, 1], palettes[11, 1], palettes[1, 1], palettes[0, 1], palettes[0, 1], palettes[4, 1],
		palettes[6, 0], palettes[6, 0], palettes[14, 0], palettes[13, 0], palettes[6, 0], palettes[0, 0], palettes[7, 0], palettes[8, 0], palettes[6, 1], palettes[5, 1], palettes[0, 1], palettes[3, 1], palettes[4, 1], palettes[10, 1], palettes[0, 1], palettes[9, 1],
		palettes[1, 0], palettes[0, 0], palettes[1, 0], palettes[14, 0], palettes[4, 0], palettes[15, 0], palettes[8, 0], palettes[15, 0], palettes[10, 1], palettes[5, 1], palettes[7, 1], palettes[12, 1], palettes[8, 1], palettes[15, 1], palettes[9, 1], palettes[12, 1],
		palettes[0, 0], palettes[4, 0], palettes[7, 0], palettes[3, 0], palettes[0, 0], palettes[10, 0], palettes[13, 0], palettes[9, 0], palettes[2, 1], palettes[9, 1], palettes[14, 1], palettes[10, 1], palettes[7, 1], palettes[6, 1], palettes[15, 1], palettes[9, 1],
		palettes[9, 0], palettes[0, 0], palettes[12, 0], palettes[13, 0], palettes[7, 0], palettes[2, 0], palettes[0, 0], palettes[2, 0], palettes[13, 1], palettes[3, 1], palettes[3, 1], palettes[13, 1], palettes[10, 1], palettes[1, 1], palettes[0, 1], palettes[0, 1],
		palettes[1, 0], palettes[8, 0], palettes[8, 0], palettes[14, 0], palettes[12, 0], palettes[3, 0], palettes[4, 0], palettes[9, 0], palettes[10, 1], palettes[1, 1], palettes[15, 1], palettes[3, 1], palettes[9, 1], palettes[6, 1], palettes[14, 1], palettes[8, 1],
		palettes[5, 0], palettes[0, 0], palettes[11, 0], palettes[7, 0], palettes[7, 0], palettes[4, 0], palettes[9, 0], palettes[4, 0], palettes[8, 1], palettes[3, 1], palettes[6, 1], palettes[4, 1], palettes[14, 1], palettes[11, 1], palettes[14, 1], palettes[13, 1],
		palettes[10, 2], palettes[1, 2], palettes[10, 2], palettes[6, 2], palettes[6, 2], palettes[2, 2], palettes[15, 2], palettes[10, 2], palettes[6, 3], palettes[10, 3], palettes[10, 3], palettes[10, 3], palettes[1, 3], palettes[11, 3], palettes[9, 3], palettes[12, 3],
		palettes[3, 2], palettes[1, 2], palettes[7, 2], palettes[11, 2], palettes[3, 2], palettes[7, 2], palettes[12, 2], palettes[15, 2], palettes[6, 3], palettes[7, 3], palettes[2, 3], palettes[15, 3], palettes[5, 3], palettes[9, 3], palettes[2, 3], palettes[4, 3],
		palettes[11, 2], palettes[15, 2], palettes[1, 2], palettes[11, 2], palettes[1, 2], palettes[6, 2], palettes[12, 2], palettes[15, 2], palettes[8, 3], palettes[0, 3], palettes[7, 3], palettes[10, 3], palettes[6, 3], palettes[6, 3], palettes[1, 3], palettes[1, 3],
		palettes[1, 2], palettes[11, 2], palettes[4, 2], palettes[3, 2], palettes[5, 2], palettes[7, 2], palettes[10, 2], palettes[14, 2], palettes[0, 3], palettes[1, 3], palettes[8, 3], palettes[13, 3], palettes[0, 3], palettes[8, 3], palettes[2, 3], palettes[4, 3],
		palettes[15, 2], palettes[1, 2], palettes[14, 2], palettes[8, 2], palettes[5, 2], palettes[4, 2], palettes[3, 2], palettes[4, 2], palettes[4, 3], palettes[14, 3], palettes[8, 3], palettes[6, 3], palettes[9, 3], palettes[14, 3], palettes[11, 3], palettes[13, 3],
		palettes[14, 2], palettes[0, 2], palettes[3, 2], palettes[14, 2], palettes[10, 2], palettes[1, 2], palettes[1, 2], palettes[13, 2], palettes[3, 3], palettes[2, 3], palettes[15, 3], palettes[15, 3], palettes[3, 3], palettes[5, 3], palettes[0, 3], palettes[8, 3],
		palettes[3, 2], palettes[3, 2], palettes[10, 2], palettes[4, 2], palettes[5, 2], palettes[15, 2], palettes[7, 2], palettes[8, 2], palettes[3, 3], palettes[2, 3], palettes[9, 3], palettes[2, 3], palettes[15, 3], palettes[1, 3], palettes[11, 3], palettes[0, 3],
		palettes[14, 2], palettes[14, 2], palettes[15, 2], palettes[12, 2], palettes[12, 2], palettes[6, 2], palettes[8, 2], palettes[13, 2], palettes[6, 3], palettes[8, 3], palettes[13, 3], palettes[15, 3], palettes[7, 3], palettes[15, 3], palettes[14, 3], palettes[15, 3]
	]));
}
