module tiledump.imagesaver;

import std.algorithm;
import std.array;
import tiledump.arrangement;
import magicalrainbows;

RGBA8888[][] convertPalettes(T, size_t paletteCount, size_t colourCount)(T[colourCount][paletteCount] palettes, bool firstColourTransparent) @safe pure {
	auto output = new RGBA8888[][](paletteCount);
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
RGBA8888[][] convertPalettes(T, size_t colourCount)(T[colourCount][] palettes, bool firstColourTransparent) @safe pure {
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
RGBA8888[][] convertPalettes(T)(const T[][] palettes, bool firstColourTransparent) @safe pure {
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

auto unflatten(T)(T[] arr, size_t width) {
    static struct Result {
        T[] arr;
        size_t width;
        int opApply(int delegate(size_t, size_t, ref T) dg) {
            int result = 0;

            for (int i = 0; i < arr.length; i++) {
                result = dg(i % width, i / width, arr[i]);
                if (result) {
                    break;
                }
            }
            return result;
        }
    }
    return Result(arr, width);
}

//void red(ref uint rgba8888, ubyte val) {
//	rgba8888 |= val;
//}
//void green(ref uint rgba8888, ubyte val) {
//	rgba8888 |= (val<<8);
//}
//void blue(ref uint rgba8888, ubyte val) {
//	rgba8888 |= (val<<16);
//}
//void alpha(ref uint rgba8888, ubyte val) {
//	rgba8888 |= (val<<24);
//}

void saveImage(size_t TileHeight, size_t TileWidth)(string path, const ubyte[TileHeight][TileWidth][] tiles, const Arrangement tilemap, const RGBA8888[][] palettes) @system
	in(tilemap.width > 0)
	in(palettes.length > 0)
{
	import imagefmt;
	const width = tilemap.width;
	const imageWidth = TileWidth * width;
	const imageHeight = TileHeight * ((tilemap.tiles.length / width) + ((tilemap.tiles.length % width) == 0 ? 0 : 1));
	RGBA8888[] buffer = new RGBA8888[](imageWidth * imageHeight);
	foreach (tileidx, tileattrs; tilemap.tiles) {
		const palette = palettes[tileattrs.palette % palettes.length];
		const pixels = tiles[tileattrs.tile % tiles.length];
		foreach (rowidx, row; pixels) {
			const x = (tileidx / width) * TileWidth + (tileattrs.flipX ? (TileWidth - 1) - rowidx : rowidx);
			foreach (colidx, pixel; row) {
				const y = (tileidx % width) * TileHeight + (tileattrs.flipY ? (TileHeight - 1) - colidx : colidx);
				buffer[(x * imageHeight + y)].red = palette[pixel % palette.length].red;
				buffer[(x * imageHeight + y)].green = palette[pixel % palette.length].green;
				buffer[(x * imageHeight + y)].blue = palette[pixel % palette.length].blue;
				buffer[(x * imageHeight + y)].alpha = palette[pixel % palette.length].alpha;
			}
		}
	}
	write_image(path, cast(int)imageWidth, cast(int)imageHeight, cast(ubyte[])buffer, 4);
}
