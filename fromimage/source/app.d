
import std.algorithm;
import std.array;
import std.file;
import std.format;
import std.getopt;
import std.logger;
import std.range;
import std.stdio;

import siryul;
import pixelmancy;

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
		"prune-empty-palettes|P", "Don't output empty palettes", &prunePalettes,
		"tileformat|f", &tileFormat
	);

	if (helpInformation.helpWanted || (args.length < 3)) {
		defaultGetoptPrinter(format!"Usage: %s <image> <tile file>"(args[0]), helpInformation.options);
		return;
	}
	const arrangement = arrangementFile ? fromFile!(Array2D!TileAttributes, YAML, DeSiryulize.optionalByDefault)(arrangementFile) : generateArrangement(arrangementStyle, 32, 32);
	const result = loadImageFile(cast(ubyte[])read(args[1]), tileFormat, arrangement);
	infof("Tiles: %sx%s", arrangement.width, arrangement.height);

	auto file = File(args[2], "wb");
	foreach (tile; result.tiles) {
		file.rawWrite(getBytes(tile));
	}
	if (writeArrangementFile) {
		File(writeArrangementFile, "w").rawWrite(result.arrangement[].map!(x => cast(SNESTileAttributes)x).array);
	}
	if (palettePath) {
		auto paletteFile = File(palettePath, "wb");
		foreach (palette; result.palette.chunks(16)) {
			if (palette.all!(x => x == RGBA32(0, 0, 0, 255))) {
				continue;
			}
			foreach (colour; palette) {
				paletteFile.rawWrite(colourToBytes(colour, paletteFormat));
			}
		}
	}
}
