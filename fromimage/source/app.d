
import std.algorithm;
import std.array;
import std.format;
import std.getopt;
import std.stdio;

import arsd.png;
import siryul;
import tiledump;
import pixelatrix;
import magicalrainbows;

void main(string[] args) {
	string palettePath;
	TileFormat tileFormat = TileFormat.intertwined4BPP;
	ArrangementStyle arrangementStyle;
	string arrangementFile;
	SupportedFormat paletteFormat;
	auto helpInformation = getopt(args,
    	std.getopt.config.caseSensitive,
		"arrangement-style|s", "Assume a specific tile arrangement style", &arrangementStyle,
		"arrangement-file|i", "Load an arrangement from a file", &arrangementFile,
		"palette|p", "Write a palette file", &palettePath,
		"palette-format|F", "Palette file format", &paletteFormat,
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
		foreach (tileAttributes; arrangement.tiles) {
			file.rawWrite(tileData(tiles[tileAttributes.tile], tileFormat));
		}
		if (palettePath) {
			auto paletteFile = File(palettePath, "wb");
			RGBA8888[] colours = img.palette.map!(x => RGBA8888(x.r, x.g, x.b, x.a)).array;
			foreach (colour; colours) {
				paletteFile.rawWrite(colourToBytes(colour, paletteFormat));
			}
		}
	}
}
