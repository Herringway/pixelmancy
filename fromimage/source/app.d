
import std.algorithm;
import std.array;
import std.format;
import std.getopt;
import std.logger;
import std.range;
import std.stdio;

import arsd.png;
import siryul;
import tilecon;
import pixelatrix;
import magicalrainbows;

void main(string[] args) {
	string palettePath;
	TileFormat tileFormat = TileFormat.intertwined4BPP;
	ArrangementStyle arrangementStyle;
	string arrangementFile;
	string writeArrangementFile;
	SupportedFormat paletteFormat;
	bool noDuplicateTiles;
	bool prunePalettes;
	auto helpInformation = getopt(args,
    	std.getopt.config.caseSensitive,
		"arrangement-style|s", "Assume a specific tile arrangement style", &arrangementStyle,
		"arrangement-file|i", "Load an arrangement from a file", &arrangementFile,
		"write-arrangement-file|a", "Write arrangement to a file", &writeArrangementFile,
		"deduplicate|d", "Only write unique tiles", &noDuplicateTiles,
		"palette|p", "Write a palette file", &palettePath,
		"palette-format|F", "Palette file format", &paletteFormat,
		"prune-empty-paletts|P", "Don't output empty palettes", &prunePalettes,
		"tileformat|f", &tileFormat
	);

	if (helpInformation.helpWanted || (args.length < 3)) {
		defaultGetoptPrinter(format!"Usage: %s <image> <tile file>"(args[0]), helpInformation.options);
		return;
	}
	if (auto img = cast(IndexedImage)readPng(args[1])) {
		if (((img.width % 8) != 0) || ((img.height % 8) != 0)) {
			stderr.writeln("Error: image dimensions are not multiples of 8!");
			return;
		}
		const tileWidth = img.width / 8;
		const tileHeight = img.height / 8;
		infof("Tiles: %sx%s", tileWidth, tileHeight);
		ubyte[8][8][] tiles;
		tiles.reserve(tileWidth * tileHeight);
		auto tileRows = cast(ubyte[8][])img.data;
		auto file = File(args[2], "wb");
		foreach (th; 0 .. tileHeight) {
			foreach (w; 0 .. tileWidth) {
				ubyte[8][8] tile;
				foreach (h; 0 .. 8) {
					tile[h] = tileRows[th * tileWidth * 8 + h * tileWidth + w];
				}
				tiles ~= tile;
			}
		}
		const arrangement = arrangementFile ? fromFile!(Arrangement,YAML, DeSiryulize.optionalByDefault)(arrangementFile) : Arrangement.generate(arrangementStyle, tiles.length, tileWidth);
		const(ubyte)[][] seenTiles;
		ConsoleFullTileArrangement[1] arrangementToWrite;
		foreach (idx, tileAttributes; arrangement.tiles) {
			const data = tileData(tiles[tileAttributes.tile], tileFormat);
			const found = seenTiles.countUntil(data);
			if (!noDuplicateTiles || (found == -1)) {
				file.rawWrite(data);
				if (noDuplicateTiles) {
					seenTiles ~= data;
				}
			}
			auto newTile = (found == -1) ? (seenTiles.length - 1) : found;
			arrangementToWrite[0].tiles[(idx / tileWidth) * 32 + (idx % tileWidth)] = SNESTileAttributes(TileAttributes(newTile, tileAttributes.palette, tileAttributes.flipX, tileAttributes.flipY));
		}
		if (writeArrangementFile) {
			File(writeArrangementFile, "w").rawWrite(arrangementToWrite[]);
		}
		if (palettePath) {
			auto paletteFile = File(palettePath, "wb");
			RGBA8888[] colours = img.palette.map!(x => RGBA8888(x.r, x.g, x.b, x.a)).array;
			auto roundUp(size_t v) {
			    return (v / 16 + !!(v % 16)) * 16;
			}
			colours.length = roundUp(colours.length);
			foreach (palette; colours.chunks(16)) {
				if (palette.all!(x => x == RGBA8888(0, 0, 0, 255))) {
					continue;
				}
				foreach (colour; palette) {
					paletteFile.rawWrite(colourToBytes(colour, paletteFormat));
				}
			}
		}
	} else {
		writeln("Invalid image");
	}
}
