module tiledump.imagesaver;

import std.algorithm;
import std.array;
import tiledump.arrangement;
import magicalrainbows;

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

void saveImage(T, Arr, P, size_t N, size_t N2)(string path, const T[] tiles, const Arr tilemap, const P[N][N2] palettes, bool firstColourTransparent = true) {
	saveImage(path, tiles.map!(x => x.pixelMatrix).array, cast(Arrangement)tilemap, convertPalettes(palettes, firstColourTransparent));
}
void saveImage(T, Arr, P, size_t N)(string path, const T[] tiles, const Arr tilemap, const P[N][] palettes, bool firstColourTransparent = true) {
	saveImage(path, tiles.map!(x => x.pixelMatrix).array, cast(Arrangement)tilemap, convertPalettes(palettes, firstColourTransparent));
}
void saveImage(T, Arr, P)(string path, const T[] tiles, const Arr tilemap, const P[][] palettes, bool firstColourTransparent = true) {
	saveImage(path, tiles.map!(x => x.pixelMatrix).array, cast(Arrangement)tilemap, convertPalettes(palettes, firstColourTransparent));
}
void saveImage(T, P, size_t N, size_t N2)(string path, const T[] tiles, const P[N][N2] palettes, size_t width, bool firstColourTransparent = true, ArrangementStyle style = ArrangementStyle.horizontal) {
	saveImage(path, tiles.map!(x => x.pixelMatrix).array, Arrangement.generate(style, tiles.length, width), convertPalettes(palettes, firstColourTransparent));
}
//void saveImage(T, P, size_t N)(string path, const T[] tiles, const P[N][] palettes, size_t width, bool firstColourTransparent = true, ArrangementStyle style = ArrangementStyle.horizontal) {
//	saveImage(path, tiles.map!(x => x.pixelMatrix).array, Arrangement.generate(style, tiles.length, width), convertPalettes(palettes, firstColourTransparent));
//}
void saveImage(T, P)(string path, const T[] tiles, const P[][] palettes, size_t width, bool firstColourTransparent = true, ArrangementStyle style = ArrangementStyle.horizontal) {
	saveImage(path, tiles.map!(x => x.pixelMatrix).array, Arrangement.generate(style, tiles.length, width), convertPalettes(palettes, firstColourTransparent));
}

void saveImage(size_t TileHeight, size_t TileWidth)(string path, const ubyte[TileHeight][TileWidth][] tiles, const Arrangement tilemap, const RGBA8888[][] palettes) @system
	in(tilemap.width > 0)
	in(palettes.length > 0)
{
	import arsd.png;
	const width = tilemap.width;
	const imageWidth = TileWidth * width;
	const imageHeight = TileHeight * ((tilemap.tiles.length / width) + ((tilemap.tiles.length % width) == 0 ? 0 : 1));
	auto img = new IndexedImage(cast(uint)imageWidth, cast(uint)imageHeight);
	foreach (palette; palettes) {
		foreach (colour; palette) {
			img.addColor(Color(colour.red, colour.green, colour.blue, colour.alpha));
		}
	}
	foreach (tileidx, tileattrs; tilemap.tiles) {
		const paletteID = tileattrs.palette % palettes.length;
		const pixels = tiles[tileattrs.tile % tiles.length];
		const baseX = (tileidx / width) * TileWidth;
		const baseY = (tileidx % width) * TileHeight;
		foreach (rowidx, row; pixels) {
			const x = baseX + (tileattrs.flipX ? ((TileWidth - 1) - rowidx) : rowidx);
			foreach (colidx, pixel; row) {
				const y = baseY + (tileattrs.flipY ? ((TileHeight - 1) - colidx) : colidx);
				img.data[(x * imageWidth) + y] = cast(ubyte)((pixel % palettes[paletteID].length) + palettes[0 .. paletteID].map!(x => x.length).sum);
			}
		}
	}
	writePng(path, img);
}
