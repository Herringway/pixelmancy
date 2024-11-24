module tilemagic.imagesaver;

import std.algorithm;
import tilemagic.arrangement;
import tilemagic.colours;
import tilemagic.util;

RGBA8888[][] convertPalettes(T, size_t colourCount)(in T[colourCount][] palettes, bool firstColourTransparent) @safe pure {
	auto output = new RGBA8888[][](palettes.length);
	foreach (pidx, palette; palettes) {
		auto newPalette = new RGBA8888[](colourCount);
		foreach (idx, colour; palette) {
			newPalette[idx] = convert!RGBA8888(colour);
		}
		if (firstColourTransparent) {
			newPalette[0].alpha = 0;
		}
		output[pidx] = newPalette;
	}
	return output;
}
RGBA8888[][] convertPalettes(T)(in T[][] palettes, bool firstColourTransparent) @safe pure {
	auto output = new RGBA8888[][](palettes.length);
	foreach (pidx, palette; palettes) {
		auto newPalette = new RGBA8888[](palette.length);
		foreach (idx, colour; palette) {
			newPalette[idx] = convert!RGBA8888(colour);
		}
		if (firstColourTransparent) {
			newPalette[0].alpha = 0;
		}
		output[pidx] = newPalette;
	}
	return output;
}

struct PalettedPixels {
	Array2D!uint pixels;
	RGBA8888[] palette;
}

PalettedPixels toPixelArray(T, Arr, P, size_t N, size_t N2)(const T[] tiles, const Arr tilemap, const P[N][N2] palettes, bool firstColourTransparent = true) {
	return toPixelArray(tiles, cast(Arrangement)tilemap, convertPalettes(palettes, firstColourTransparent));
}
PalettedPixels toPixelArray(T, Arr, P, size_t N)(const T[] tiles, const Arr tilemap, const P[N][] palettes, bool firstColourTransparent = true) {
	return toPixelArray(tiles, cast(Arrangement)tilemap, convertPalettes(palettes, firstColourTransparent));
}
PalettedPixels toPixelArray(T, Arr, P)(const T[] tiles, const Arr tilemap, const P[][] palettes, bool firstColourTransparent = true) {
	return toPixelArray(tiles, cast(Arrangement)tilemap, convertPalettes(palettes, firstColourTransparent));
}
PalettedPixels toPixelArray(T, P, size_t N, size_t N2)(const T[] tiles, const P[N][N2] palettes, size_t width, bool firstColourTransparent = true, ArrangementStyle style = ArrangementStyle.horizontal) {
	return toPixelArray(tiles, Arrangement.generate(style, tiles.length, width), convertPalettes(palettes, firstColourTransparent));
}
PalettedPixels toPixelArray(T, P)(const T[] tiles, const P[][] palettes, size_t width, bool firstColourTransparent = true, ArrangementStyle style = ArrangementStyle.horizontal) {
	import std.logger; debug infof("%s", Arrangement.generate(style, tiles.length, width));
	return toPixelArray(tiles, Arrangement.generate(style, tiles.length, width), convertPalettes(palettes, firstColourTransparent));
}

PalettedPixels toPixelArray(Tile)(const Tile[] tiles, const Arrangement tilemap, const RGBA8888[][] palettes) @system
	in(tilemap.width > 0, "Tilemap has no width")
	in(palettes.length > 0, "No palettes")
{
	const width = tilemap.width;
	const imageWidth = tiles[0].width * width;
	const imageHeight = tiles[0].height * ((tilemap.tiles.length / width) + ((tilemap.tiles.length % width) == 0 ? 0 : 1));
	auto result = PalettedPixels(Array2D!uint(imageWidth, imageHeight));
	foreach (palette; palettes) {
		foreach (colour; palette) {
			result.palette ~= colour;
		}
	}
	foreach (tileidx, tileattrs; tilemap.tiles) {
		const paletteID = tileattrs.palette % palettes.length;
		const pixels = tiles[tileattrs.tile % tiles.length];
		const baseX = (tileidx % width) * tiles[0].height;
		const baseY = (tileidx / width) * tiles[0].width;
		foreach (size_t tileX, size_t tileY, ubyte pixel; pixels) {
			const x = baseX + (tileattrs.flipX ? ((tiles[0].width - 1) - tileX) : tileX);
			const y = baseY + (tileattrs.flipY ? ((tiles[0].height - 1) - tileY) : tileY);
			result.pixels[x, y] = cast(uint)(paletteID * palettes[0].length + pixel);
		}
	}
	return result;
}

Array2D!RGBA8888 toTrueColour(PalettedPixels paletted) {
	auto result = Array2D!RGBA8888(paletted.pixels.width, paletted.pixels.height);
	foreach (x, y, pixel; paletted.pixels) {
		result[x, y] = paletted.palette[pixel];
	}
	return result;
}
