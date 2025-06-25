import std.algorithm;
import std.array;
import std.conv;
import std.format;
import std.getopt;
import std.meta;
import std.range;
import std.stdio;
import std.string;
import std.traits;

import pixelmancy;
import siryul;

const(Array2D!TileAttributes) getArrangement(const string path, ArrangementFormat format, size_t width, const Array2D!TileAttributes defaultArrangement) @safe {
	if (path != "") {
		final switch (format) {
			case ArrangementFormat.snes:
				const data = readData(path);
				auto raw = (cast(const(SNESTileAttributes)[])(data)).map!(x => cast(TileAttributes)x).array;
				return array2D(raw, width, raw.length / width);
		}
	} else {
		return defaultArrangement;
	}
}
const(Array2D!RGBA8888) getPalette(const string path, SupportedFormat format, size_t paletteSize, bool firstColourTransparent, const Array2D!RGBA8888 preset) @safe {
	if (path != "") {
		const data = readData(path);
		auto colours = bytesToColors!RGBA8888(data, format);
		if (firstColourTransparent) {
			foreach (ref palette; colours.chunks(paletteSize)) {
				palette[0].alpha = 0;
			}
		}
		return array2D(colours, paletteSize, colours.length / paletteSize);
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

const(Array2D!RGBA8888) getPalette(PalettePreset preset) @safe pure {
	template convRGBA8888(alias T) {
		enum convRGBA8888 = array2D(T.map!(x => x.convert!RGBA8888).array, T.length, 1);
	}
	final switch(preset) {
		case PalettePreset.ansi:
			return defaultPalette;
		case PalettePreset.gb:
			return convRGBA8888!GameBoy;
		case PalettePreset.cga16:
			return convRGBA8888!CGA16;
		case PalettePreset.gbPocket:
			return convRGBA8888!GameBoyPocket;
	}
}

void main(string[] args) @system {
	string outFile = "out.png";
	string arrangementFile;
	string paletteFile;
	size_t forceWidth = 32;
	string arrangementDoc;
	PalettePreset palettePreset;
	bool firstColourNotTransparent;
	TileFormat tileFormat = TileFormat.intertwined4BPP;
	ArrangementFormat arrangementFormat;
	SupportedFormat paletteFormat;
	ArrangementStyle arrangementStyle;
	auto helpInformation = getopt(args,
		std.getopt.config.caseSensitive,
		"arrangement|a", "Use a tile arrangement file", &arrangementFile,
		"arrangementdoc|i", "Use a tile arrangement doc", &arrangementDoc,
		"arrangement-style|s", "Use a specific tile arrangement generator", &arrangementStyle,
		"palette|p", "Use a palette file", &paletteFile,
		"palette-format|F", "Palette file format", &paletteFormat,
		"output|o", "Write to file", &outFile,
		"preset-palette|P", "Use a preset palette", &palettePreset,
		"width|w", "Force image width", &forceWidth,
		"first-colour-not-transparent", "First colour in palette isn't transparent", &firstColourNotTransparent,
		"tileformat|f", &tileFormat
	);

	if (helpInformation.helpWanted || (args.length < 2)) {
		defaultGetoptPrinter(format!"Usage: %s <tiles>"(args[0]), helpInformation.options);
		return;
	}
	assert(forceWidth != 0);
	const tiles = getTiles(readData(args[1]), tileFormat);
	const arrangement = arrangementDoc ? fromFile!(Array2D!TileAttributes, YAML, DeSiryulize.optionalByDefault)(arrangementDoc) : getArrangement(arrangementFile, arrangementFormat, forceWidth, generateArrangement(arrangementStyle, tiles.length / forceWidth, forceWidth));
	auto palettes = getPalette(paletteFile, paletteFormat, tileFormat.colours, !firstColourNotTransparent, getPalette(palettePreset));
	writeln("Saving '", outFile, "'");
	auto pixels = tiles.toPaletteCoords(arrangement).toTrueColour(palettes);
	writePng(outFile, new TrueColorImage(cast(int)pixels.width, cast(int)pixels.height, cast(ubyte[])pixels[]));
}

ubyte[] readData(string filename) @trusted {
	import std.file;
	return cast(ubyte[])read(filename);
}

static immutable defaultPalette = array2D([RGBA8888(0,0,0, 255), RGBA8888(128,0,0, 255), RGBA8888(0,128,0, 255), RGBA8888(128,128,0, 255), RGBA8888(0,0,128, 255), RGBA8888(128,0,128, 255), RGBA8888(0,128,128, 255), RGBA8888(192,192,192, 255), RGBA8888(128,128,128, 255), RGBA8888(255,0,0, 255), RGBA8888(0,255,0, 255), RGBA8888(255,255,0, 255), RGBA8888(0,0,255, 255), RGBA8888(255,0,255, 255), RGBA8888(0,255,255, 255), RGBA8888(255,255,255, 255), RGBA8888(0,0,0, 255), RGBA8888(0,0,95, 255), RGBA8888(0,0,135, 255), RGBA8888(0,0,175, 255), RGBA8888(0,0,215, 255), RGBA8888(0,0,255, 255), RGBA8888(0,95,0, 255), RGBA8888(0,95,95, 255), RGBA8888(0,95,135, 255), RGBA8888(0,95,175, 255), RGBA8888(0,95,215, 255), RGBA8888(0,95,255, 255), RGBA8888(0,135,0, 255), RGBA8888(0,135,95, 255), RGBA8888(0,135,135, 255), RGBA8888(0,135,175, 255), RGBA8888(0,135,215, 255), RGBA8888(0,135,255, 255), RGBA8888(0,175,0, 255), RGBA8888(0,175,95, 255), RGBA8888(0,175,135, 255), RGBA8888(0,175,175, 255), RGBA8888(0,175,215, 255), RGBA8888(0,175,255, 255), RGBA8888(0,215,0, 255), RGBA8888(0,215,95, 255), RGBA8888(0,215,135, 255), RGBA8888(0,215,175, 255), RGBA8888(0,215,215, 255), RGBA8888(0,215,255, 255), RGBA8888(0,255,0, 255), RGBA8888(0,255,95, 255), RGBA8888(0,255,135, 255), RGBA8888(0,255,175, 255), RGBA8888(0,255,215, 255), RGBA8888(0,255,255, 255), RGBA8888(95,0,0, 255), RGBA8888(95,0,95, 255), RGBA8888(95,0,135, 255), RGBA8888(95,0,175, 255), RGBA8888(95,0,215, 255), RGBA8888(95,0,255, 255), RGBA8888(95,95,0, 255), RGBA8888(95,95,95, 255), RGBA8888(95,95,135, 255), RGBA8888(95,95,175, 255), RGBA8888(95,95,215, 255), RGBA8888(95,95,255, 255), RGBA8888(95,135,0, 255), RGBA8888(95,135,95, 255), RGBA8888(95,135,135, 255), RGBA8888(95,135,175, 255), RGBA8888(95,135,215, 255), RGBA8888(95,135,255, 255), RGBA8888(95,175,0, 255), RGBA8888(95,175,95, 255), RGBA8888(95,175,135, 255), RGBA8888(95,175,175, 255), RGBA8888(95,175,215, 255), RGBA8888(95,175,255, 255), RGBA8888(95,215,0, 255), RGBA8888(95,215,95, 255), RGBA8888(95,215,135, 255), RGBA8888(95,215,175, 255), RGBA8888(95,215,215, 255), RGBA8888(95,215,255, 255), RGBA8888(95,255,0, 255), RGBA8888(95,255,95, 255), RGBA8888(95,255,135, 255), RGBA8888(95,255,175, 255), RGBA8888(95,255,215, 255), RGBA8888(95,255,255, 255), RGBA8888(135,0,0, 255), RGBA8888(135,0,95, 255), RGBA8888(135,0,135, 255), RGBA8888(135,0,175, 255), RGBA8888(135,0,215, 255), RGBA8888(135,0,255, 255), RGBA8888(135,95,0, 255), RGBA8888(135,95,95, 255), RGBA8888(135,95,135, 255), RGBA8888(135,95,175, 255), RGBA8888(135,95,215, 255), RGBA8888(135,95,255, 255), RGBA8888(135,135,0, 255), RGBA8888(135,135,95, 255), RGBA8888(135,135,135, 255), RGBA8888(135,135,175, 255), RGBA8888(135,135,215, 255), RGBA8888(135,135,255, 255), RGBA8888(135,175,0, 255), RGBA8888(135,175,95, 255), RGBA8888(135,175,135, 255), RGBA8888(135,175,175, 255), RGBA8888(135,175,215, 255), RGBA8888(135,175,255, 255), RGBA8888(135,215,0, 255), RGBA8888(135,215,95, 255), RGBA8888(135,215,135, 255), RGBA8888(135,215,175, 255), RGBA8888(135,215,215, 255), RGBA8888(135,215,255, 255), RGBA8888(135,255,0, 255), RGBA8888(135,255,95, 255), RGBA8888(135,255,135, 255), RGBA8888(135,255,175, 255), RGBA8888(135,255,215, 255), RGBA8888(135,255,255, 255), RGBA8888(175,0,0, 255), RGBA8888(175,0,95, 255), RGBA8888(175,0,135, 255), RGBA8888(175,0,175, 255), RGBA8888(175,0,215, 255), RGBA8888(175,0,255, 255), RGBA8888(175,95,0, 255), RGBA8888(175,95,95, 255), RGBA8888(175,95,135, 255), RGBA8888(175,95,175, 255), RGBA8888(175,95,215, 255), RGBA8888(175,95,255, 255), RGBA8888(175,135,0, 255), RGBA8888(175,135,95, 255), RGBA8888(175,135,135, 255), RGBA8888(175,135,175, 255), RGBA8888(175,135,215, 255), RGBA8888(175,135,255, 255), RGBA8888(175,175,0, 255), RGBA8888(175,175,95, 255), RGBA8888(175,175,135, 255), RGBA8888(175,175,175, 255), RGBA8888(175,175,215, 255), RGBA8888(175,175,255, 255), RGBA8888(175,215,0, 255), RGBA8888(175,215,95, 255), RGBA8888(175,215,135, 255), RGBA8888(175,215,175, 255), RGBA8888(175,215,215, 255), RGBA8888(175,215,255, 255), RGBA8888(175,255,0, 255), RGBA8888(175,255,95, 255), RGBA8888(175,255,135, 255), RGBA8888(175,255,175, 255), RGBA8888(175,255,215, 255), RGBA8888(175,255,255, 255), RGBA8888(215,0,0, 255), RGBA8888(215,0,95, 255), RGBA8888(215,0,135, 255), RGBA8888(215,0,175, 255), RGBA8888(215,0,215, 255), RGBA8888(215,0,255, 255), RGBA8888(215,95,0, 255), RGBA8888(215,95,95, 255), RGBA8888(215,95,135, 255), RGBA8888(215,95,175, 255), RGBA8888(215,95,215, 255), RGBA8888(215,95,255, 255), RGBA8888(215,135,0, 255), RGBA8888(215,135,95, 255), RGBA8888(215,135,135, 255), RGBA8888(215,135,175, 255), RGBA8888(215,135,215, 255), RGBA8888(215,135,255, 255), RGBA8888(215,175,0, 255), RGBA8888(215,175,95, 255), RGBA8888(215,175,135, 255), RGBA8888(215,175,175, 255), RGBA8888(215,175,215, 255), RGBA8888(215,175,255, 255), RGBA8888(215,215,0, 255), RGBA8888(215,215,95, 255), RGBA8888(215,215,135, 255), RGBA8888(215,215,175, 255), RGBA8888(215,215,215, 255), RGBA8888(215,215,255, 255), RGBA8888(215,255,0, 255), RGBA8888(215,255,95, 255), RGBA8888(215,255,135, 255), RGBA8888(215,255,175, 255), RGBA8888(215,255,215, 255), RGBA8888(215,255,255, 255), RGBA8888(255,0,0, 255), RGBA8888(255,0,95, 255), RGBA8888(255,0,135, 255), RGBA8888(255,0,175, 255), RGBA8888(255,0,215, 255), RGBA8888(255,0,255, 255), RGBA8888(255,95,0, 255), RGBA8888(255,95,95, 255), RGBA8888(255,95,135, 255), RGBA8888(255,95,175, 255), RGBA8888(255,95,215, 255), RGBA8888(255,95,255, 255), RGBA8888(255,135,0, 255), RGBA8888(255,135,95, 255), RGBA8888(255,135,135, 255), RGBA8888(255,135,175, 255), RGBA8888(255,135,215, 255), RGBA8888(255,135,255, 255), RGBA8888(255,175,0, 255), RGBA8888(255,175,95, 255), RGBA8888(255,175,135, 255), RGBA8888(255,175,175, 255), RGBA8888(255,175,215, 255), RGBA8888(255,175,255, 255), RGBA8888(255,215,0, 255), RGBA8888(255,215,95, 255), RGBA8888(255,215,135, 255), RGBA8888(255,215,175, 255), RGBA8888(255,215,215, 255), RGBA8888(255,215,255, 255), RGBA8888(255,255,0, 255), RGBA8888(255,255,95, 255), RGBA8888(255,255,135, 255), RGBA8888(255,255,175, 255), RGBA8888(255,255,215, 255), RGBA8888(255,255,255, 255), RGBA8888(8,8,8, 255), RGBA8888(18,18,18, 255), RGBA8888(28,28,28, 255), RGBA8888(38,38,38, 255), RGBA8888(48,48,48, 255), RGBA8888(58,58,58, 255), RGBA8888(68,68,68, 255), RGBA8888(78,78,78, 255), RGBA8888(88,88,88, 255), RGBA8888(98,98,98, 255), RGBA8888(108,108,108, 255), RGBA8888(118,118,118, 255), RGBA8888(128,128,128, 255), RGBA8888(138,138,138, 255), RGBA8888(148,148,148, 255), RGBA8888(158,158,158, 255), RGBA8888(168,168,168, 255), RGBA8888(178,178,178, 255), RGBA8888(188,188,188, 255), RGBA8888(198,198,198, 255), RGBA8888(208,208,208, 255), RGBA8888(218,218,218, 255), RGBA8888(228,228,228, 255), RGBA8888(238,238,238, 255)], 256, 1);
