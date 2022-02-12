import std.algorithm;
import std.array;
import std.conv;
import std.format;
import std.getopt;
import std.meta;
import std.range;
import std.random;
import std.stdio;
import std.string;
import std.traits;

import tiledump.arrangement;
import pixelatrix;
import magicalrainbows;
import rando.palette;

const(Arrangement) getArrangement(const string path, ArrangementFormat format, const Arrangement defaultArrangement) @safe {
	if (path != "") {
		final switch (format) {
			case ArrangementFormat.snes:
				const data = readData(path);
				return cast(Arrangement)*interpretData!SNESTileArrangement(data[0 .. SNESTileArrangement.sizeof]);
		}
	} else {
		return defaultArrangement;
	}
}
RGBA8888[][] getPalette(const string path, SupportedFormat format, size_t paletteSize, bool firstColourTransparent, RGBA8888[][] preset) @safe {
	if (path != "") {
		const data = readData(path);
		auto colours = bytesToColors!RGBA8888(data, format).chunks(paletteSize);
		if (firstColourTransparent) {
			foreach (ref palette; colours) {
				palette[0].alpha = 0;
			}
		}
		return colours.array;
	} else {
		return preset;
	}
}

enum PalettePreset {
	ansi,
	cga16,
	gb,
	gbPocket
}

RGBA8888[][] getPalette(PalettePreset preset) @safe pure {
	final switch(preset) {
		case PalettePreset.ansi: return defaultPalette.map!(x => x.dup).array;
		case PalettePreset.gb: return [GameBoy.map!(x => x.convert!RGBA8888).array];
		case PalettePreset.cga16: return [CGA16.map!(x => x.convert!RGBA8888).array];
		case PalettePreset.gbPocket: return [GameBoyPocket.map!(x => x.convert!RGBA8888).array];
	}
}


void main(string[] args) @system {
	string outFile = "out.png";
	string arrangementFile;
	string paletteFile;
	size_t forceWidth;
	bool randomize;
	ColourRandomizationLevel randomizationLevel = ColourRandomizationLevel.randomHue;
	PalettePreset palettePreset;
	bool firstColourNotTransparent;
	TileFormat tileFormat = TileFormat.intertwined4BPP;
	ArrangementFormat arrangementFormat;
	SupportedFormat paletteFormat;
	ArrangementStyle arrangementStyle;
	auto helpInformation = getopt(args,
    	std.getopt.config.caseSensitive,
		"arrangement|a", "Use a tile arrangement file", &arrangementFile,
		"arrangement-style|s", "Use a specific tile arrangement generator", &arrangementStyle,
		"palette|p", "Use a palette file", &paletteFile,
		"output|o", "Write to file", &outFile,
		"preset-palette|P", "Use a preset palette", &palettePreset,
		"width|w", "Force image width", &forceWidth,
		"randomize|r", "Randomize palette", &randomize,
		"randomization-level|R", "Palette randomization level", &randomizationLevel,
		"first-colour-not-transparent", "First colour in palette isn't transparent", &firstColourNotTransparent,
		"tileformat|f", &tileFormat
	);

	if (helpInformation.helpWanted || (args.length < 2)) {
		defaultGetoptPrinter("Some information about the program.", helpInformation.options);
	}
	const tiles = pixelMatrices(readData(args[1]), tileFormat);
	const arrangement = getArrangement(arrangementFile, arrangementFormat, Arrangement.generate(arrangementStyle, tiles.length, forceWidth));
	auto palettes = getPalette(paletteFile, paletteFormat, tileFormat.colours, !firstColourNotTransparent, getPalette(palettePreset));
	if (randomize) {
		foreach (ref palette; palettes) {
			palette = randomizePalette(palette, randomizationLevel, rndGen.front);
		}
	}
	writeln("Saving '", outFile, "'");
	saveImage(outFile, tiles, arrangement, palettes);
}

ubyte[] readData(string filename) @trusted {
	import std.file;
	return cast(ubyte[])read(filename);
}
auto interpretData(T)(const ubyte[] data) {
	import reversineer;
	T* game = new T;
	data.read!T(game);
	return game;
}



static immutable defaultPalette = [[RGBA8888(0,0,0, 255), RGBA8888(128,0,0, 255), RGBA8888(0,128,0, 255), RGBA8888(128,128,0, 255), RGBA8888(0,0,128, 255), RGBA8888(128,0,128, 255), RGBA8888(0,128,128, 255), RGBA8888(192,192,192, 255), RGBA8888(128,128,128, 255), RGBA8888(255,0,0, 255), RGBA8888(0,255,0, 255), RGBA8888(255,255,0, 255), RGBA8888(0,0,255, 255), RGBA8888(255,0,255, 255), RGBA8888(0,255,255, 255), RGBA8888(255,255,255, 255), RGBA8888(0,0,0, 255), RGBA8888(0,0,95, 255), RGBA8888(0,0,135, 255), RGBA8888(0,0,175, 255), RGBA8888(0,0,215, 255), RGBA8888(0,0,255, 255), RGBA8888(0,95,0, 255), RGBA8888(0,95,95, 255), RGBA8888(0,95,135, 255), RGBA8888(0,95,175, 255), RGBA8888(0,95,215, 255), RGBA8888(0,95,255, 255), RGBA8888(0,135,0, 255), RGBA8888(0,135,95, 255), RGBA8888(0,135,135, 255), RGBA8888(0,135,175, 255), RGBA8888(0,135,215, 255), RGBA8888(0,135,255, 255), RGBA8888(0,175,0, 255), RGBA8888(0,175,95, 255), RGBA8888(0,175,135, 255), RGBA8888(0,175,175, 255), RGBA8888(0,175,215, 255), RGBA8888(0,175,255, 255), RGBA8888(0,215,0, 255), RGBA8888(0,215,95, 255), RGBA8888(0,215,135, 255), RGBA8888(0,215,175, 255), RGBA8888(0,215,215, 255), RGBA8888(0,215,255, 255), RGBA8888(0,255,0, 255), RGBA8888(0,255,95, 255), RGBA8888(0,255,135, 255), RGBA8888(0,255,175, 255), RGBA8888(0,255,215, 255), RGBA8888(0,255,255, 255), RGBA8888(95,0,0, 255), RGBA8888(95,0,95, 255), RGBA8888(95,0,135, 255), RGBA8888(95,0,175, 255), RGBA8888(95,0,215, 255), RGBA8888(95,0,255, 255), RGBA8888(95,95,0, 255), RGBA8888(95,95,95, 255), RGBA8888(95,95,135, 255), RGBA8888(95,95,175, 255), RGBA8888(95,95,215, 255), RGBA8888(95,95,255, 255), RGBA8888(95,135,0, 255), RGBA8888(95,135,95, 255), RGBA8888(95,135,135, 255), RGBA8888(95,135,175, 255), RGBA8888(95,135,215, 255), RGBA8888(95,135,255, 255), RGBA8888(95,175,0, 255), RGBA8888(95,175,95, 255), RGBA8888(95,175,135, 255), RGBA8888(95,175,175, 255), RGBA8888(95,175,215, 255), RGBA8888(95,175,255, 255), RGBA8888(95,215,0, 255), RGBA8888(95,215,95, 255), RGBA8888(95,215,135, 255), RGBA8888(95,215,175, 255), RGBA8888(95,215,215, 255), RGBA8888(95,215,255, 255), RGBA8888(95,255,0, 255), RGBA8888(95,255,95, 255), RGBA8888(95,255,135, 255), RGBA8888(95,255,175, 255), RGBA8888(95,255,215, 255), RGBA8888(95,255,255, 255), RGBA8888(135,0,0, 255), RGBA8888(135,0,95, 255), RGBA8888(135,0,135, 255), RGBA8888(135,0,175, 255), RGBA8888(135,0,215, 255), RGBA8888(135,0,255, 255), RGBA8888(135,95,0, 255), RGBA8888(135,95,95, 255), RGBA8888(135,95,135, 255), RGBA8888(135,95,175, 255), RGBA8888(135,95,215, 255), RGBA8888(135,95,255, 255), RGBA8888(135,135,0, 255), RGBA8888(135,135,95, 255), RGBA8888(135,135,135, 255), RGBA8888(135,135,175, 255), RGBA8888(135,135,215, 255), RGBA8888(135,135,255, 255), RGBA8888(135,175,0, 255), RGBA8888(135,175,95, 255), RGBA8888(135,175,135, 255), RGBA8888(135,175,175, 255), RGBA8888(135,175,215, 255), RGBA8888(135,175,255, 255), RGBA8888(135,215,0, 255), RGBA8888(135,215,95, 255), RGBA8888(135,215,135, 255), RGBA8888(135,215,175, 255), RGBA8888(135,215,215, 255), RGBA8888(135,215,255, 255), RGBA8888(135,255,0, 255), RGBA8888(135,255,95, 255), RGBA8888(135,255,135, 255), RGBA8888(135,255,175, 255), RGBA8888(135,255,215, 255), RGBA8888(135,255,255, 255), RGBA8888(175,0,0, 255), RGBA8888(175,0,95, 255), RGBA8888(175,0,135, 255), RGBA8888(175,0,175, 255), RGBA8888(175,0,215, 255), RGBA8888(175,0,255, 255), RGBA8888(175,95,0, 255), RGBA8888(175,95,95, 255), RGBA8888(175,95,135, 255), RGBA8888(175,95,175, 255), RGBA8888(175,95,215, 255), RGBA8888(175,95,255, 255), RGBA8888(175,135,0, 255), RGBA8888(175,135,95, 255), RGBA8888(175,135,135, 255), RGBA8888(175,135,175, 255), RGBA8888(175,135,215, 255), RGBA8888(175,135,255, 255), RGBA8888(175,175,0, 255), RGBA8888(175,175,95, 255), RGBA8888(175,175,135, 255), RGBA8888(175,175,175, 255), RGBA8888(175,175,215, 255), RGBA8888(175,175,255, 255), RGBA8888(175,215,0, 255), RGBA8888(175,215,95, 255), RGBA8888(175,215,135, 255), RGBA8888(175,215,175, 255), RGBA8888(175,215,215, 255), RGBA8888(175,215,255, 255), RGBA8888(175,255,0, 255), RGBA8888(175,255,95, 255), RGBA8888(175,255,135, 255), RGBA8888(175,255,175, 255), RGBA8888(175,255,215, 255), RGBA8888(175,255,255, 255), RGBA8888(215,0,0, 255), RGBA8888(215,0,95, 255), RGBA8888(215,0,135, 255), RGBA8888(215,0,175, 255), RGBA8888(215,0,215, 255), RGBA8888(215,0,255, 255), RGBA8888(215,95,0, 255), RGBA8888(215,95,95, 255), RGBA8888(215,95,135, 255), RGBA8888(215,95,175, 255), RGBA8888(215,95,215, 255), RGBA8888(215,95,255, 255), RGBA8888(215,135,0, 255), RGBA8888(215,135,95, 255), RGBA8888(215,135,135, 255), RGBA8888(215,135,175, 255), RGBA8888(215,135,215, 255), RGBA8888(215,135,255, 255), RGBA8888(215,175,0, 255), RGBA8888(215,175,95, 255), RGBA8888(215,175,135, 255), RGBA8888(215,175,175, 255), RGBA8888(215,175,215, 255), RGBA8888(215,175,255, 255), RGBA8888(215,215,0, 255), RGBA8888(215,215,95, 255), RGBA8888(215,215,135, 255), RGBA8888(215,215,175, 255), RGBA8888(215,215,215, 255), RGBA8888(215,215,255, 255), RGBA8888(215,255,0, 255), RGBA8888(215,255,95, 255), RGBA8888(215,255,135, 255), RGBA8888(215,255,175, 255), RGBA8888(215,255,215, 255), RGBA8888(215,255,255, 255), RGBA8888(255,0,0, 255), RGBA8888(255,0,95, 255), RGBA8888(255,0,135, 255), RGBA8888(255,0,175, 255), RGBA8888(255,0,215, 255), RGBA8888(255,0,255, 255), RGBA8888(255,95,0, 255), RGBA8888(255,95,95, 255), RGBA8888(255,95,135, 255), RGBA8888(255,95,175, 255), RGBA8888(255,95,215, 255), RGBA8888(255,95,255, 255), RGBA8888(255,135,0, 255), RGBA8888(255,135,95, 255), RGBA8888(255,135,135, 255), RGBA8888(255,135,175, 255), RGBA8888(255,135,215, 255), RGBA8888(255,135,255, 255), RGBA8888(255,175,0, 255), RGBA8888(255,175,95, 255), RGBA8888(255,175,135, 255), RGBA8888(255,175,175, 255), RGBA8888(255,175,215, 255), RGBA8888(255,175,255, 255), RGBA8888(255,215,0, 255), RGBA8888(255,215,95, 255), RGBA8888(255,215,135, 255), RGBA8888(255,215,175, 255), RGBA8888(255,215,215, 255), RGBA8888(255,215,255, 255), RGBA8888(255,255,0, 255), RGBA8888(255,255,95, 255), RGBA8888(255,255,135, 255), RGBA8888(255,255,175, 255), RGBA8888(255,255,215, 255), RGBA8888(255,255,255, 255), RGBA8888(8,8,8, 255), RGBA8888(18,18,18, 255), RGBA8888(28,28,28, 255), RGBA8888(38,38,38, 255), RGBA8888(48,48,48, 255), RGBA8888(58,58,58, 255), RGBA8888(68,68,68, 255), RGBA8888(78,78,78, 255), RGBA8888(88,88,88, 255), RGBA8888(98,98,98, 255), RGBA8888(108,108,108, 255), RGBA8888(118,118,118, 255), RGBA8888(128,128,128, 255), RGBA8888(138,138,138, 255), RGBA8888(148,148,148, 255), RGBA8888(158,158,158, 255), RGBA8888(168,168,168, 255), RGBA8888(178,178,178, 255), RGBA8888(188,188,188, 255), RGBA8888(198,198,198, 255), RGBA8888(208,208,208, 255), RGBA8888(218,218,218, 255), RGBA8888(228,228,228, 255), RGBA8888(238,238,238, 255)]];
