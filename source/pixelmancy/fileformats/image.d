// FYI: There used to be image resize code in here directly, but I moved it to `imageresize.d`.
/++
	This file imports all available image decoders in the arsd library, and provides convenient functions to load image regardless of it's format. Main functions: [loadImageFromFile] and [loadImageFromMemory].


	$(WARNING
		This module is exempt from my usual build-compatibility guarantees. I may add new built-time dependency modules to it at any time without notice.

		You should either copy the `image.d` module and the pieces you use to your own project, or always use it along with the rest of the repo and `dmd -i`, or the dub `arsd-official:image_files` subpackage, which both will include new files automatically and avoid breaking your build.
	)

	History:
		The image resize code used to live directly in here, but has now moved to a new module, [pixelmancy.fileformats.imageresize]. It is public imported here for compatibility, but the build has changed as of December 25, 2020.
+/
module pixelmancy.fileformats.image;

import pixelmancy.colours.formats;
import pixelmancy.fileformats.bmp;
import pixelmancy.fileformats.color;
import pixelmancy.fileformats.dds;
import pixelmancy.fileformats.imageresize;
import pixelmancy.fileformats.jpeg;
import pixelmancy.fileformats.pcx;
import pixelmancy.fileformats.png;
import pixelmancy.fileformats.svg;
import pixelmancy.fileformats.targa;
import pixelmancy.util;

import core.memory;

MemoryImage readSvg(string filename) {
	import std.file;
	return readSvg(cast(const(ubyte)[]) readText(filename));
}

MemoryImage readSvg(const(ubyte)[] rawData) {
		// Load
		NSVG* image = nsvgParse(cast(const(char)[]) rawData);

		if(image is null)
			return null;

		int w = cast(int) image.width;
		int h = cast(int) image.height;

		NSVGRasterizer rast = nsvgCreateRasterizer();
		auto img = new TrueColorImage(w, h);
		rasterize(rast, image, 0, 0, 1, img.colours[].ptr, w, h, w*4);
		image.kill();

		return img;
}
/*@safe*/ unittest {
	{
		auto rendered = readSvg("testdata/test.svg");
		assert(rendered.width == 256);
		assert(rendered.height == 256);
		assert(rendered[0, 0] == RGBA32(0, 0, 255, 255));
		assert(rendered[128, 0] == RGBA32(0, 255, 0, 255));
		assert(rendered[0, 128] == RGBA32(255, 0, 0, 255));
		assert(rendered[128, 128].alpha == 0); // the colour from the adjacent squares bleeds over a bit, but if it's fully transparent it's fine
	}
}

private bool strEquCI (const(char)[] s0, const(char)[] s1) pure nothrow @safe @nogc {
	if (s0.length != s1.length) return false;
	foreach (immutable idx, char ch; s0) {
		if (ch >= 'A' && ch <= 'Z') ch += 32; // poor man's tolower()
		char c1 = s1[idx];
		if (c1 >= 'A' && c1 <= 'Z') c1 += 32; // poor man's tolower()
		if (ch != c1) return false;
	}
	return true;
}


/// Image formats `pixelmancy.fileformats.image` can load (except `Unknown`, of course).
enum ImageFileFormat {
	Unknown, ///
	Png, ///
	Bmp, ///
	Jpeg, ///
	Tga, ///
	Gif, /// we can't load it yet, but we can at least detect it
	Pcx, /// can load 8BPP and 24BPP pcx images
	Dds, /// can load ARGB8888, DXT1, DXT3, DXT5 dds images (without mipmaps)
	Svg, /// will rasterize simple svg images
}


/// Try to guess image format from file extension.
public ImageFileFormat guessImageFormatFromExtension (const(char)[] filename) @safe {
	if (filename.length < 2) return ImageFileFormat.Unknown;
	size_t extpos = filename.length;
	version(Windows) {
		while (extpos > 0 && filename[extpos-1] != '.' && filename[extpos-1] != '/' && filename[extpos-1] != '\\' && filename[extpos-1] != ':') --extpos;
	} else {
		while (extpos > 0 && filename[extpos-1] != '.' && filename[extpos-1] != '/') --extpos;
	}
	if (extpos == 0 || filename[extpos-1] != '.') return ImageFileFormat.Unknown;
	auto ext = filename[extpos..$];
	if (strEquCI(ext, "png")) return ImageFileFormat.Png;
	if (strEquCI(ext, "bmp")) return ImageFileFormat.Bmp;
	if (strEquCI(ext, "jpg") || strEquCI(ext, "jpeg")) return ImageFileFormat.Jpeg;
	if (strEquCI(ext, "gif")) return ImageFileFormat.Gif;
	if (strEquCI(ext, "tga")) return ImageFileFormat.Tga;
	if (strEquCI(ext, "pcx")) return ImageFileFormat.Pcx;
	if (strEquCI(ext, "dds")) return ImageFileFormat.Dds;
	if (strEquCI(ext, "svg")) return ImageFileFormat.Svg;
	return ImageFileFormat.Unknown;
}

@safe unittest {
	assert(guessImageFormatFromExtension("test.png") == ImageFileFormat.Png);
	assert(guessImageFormatFromExtension("test.PNG") == ImageFileFormat.Png);
	assert(guessImageFormatFromExtension("test.gif") == ImageFileFormat.Gif);
	assert(guessImageFormatFromExtension("test.GIF") == ImageFileFormat.Gif);
	assert(guessImageFormatFromExtension("test.bmp") == ImageFileFormat.Bmp);
	assert(guessImageFormatFromExtension("test.BMP") == ImageFileFormat.Bmp);
	assert(guessImageFormatFromExtension("test.tga") == ImageFileFormat.Tga);
	assert(guessImageFormatFromExtension("test.TGA") == ImageFileFormat.Tga);
	assert(guessImageFormatFromExtension("test.dds") == ImageFileFormat.Dds);
	assert(guessImageFormatFromExtension("test.DDS") == ImageFileFormat.Dds);
	assert(guessImageFormatFromExtension("test.svg") == ImageFileFormat.Svg);
	assert(guessImageFormatFromExtension("test.SVG") == ImageFileFormat.Svg);
	assert(guessImageFormatFromExtension("test.jpg") == ImageFileFormat.Jpeg);
	assert(guessImageFormatFromExtension("test.JPG") == ImageFileFormat.Jpeg);
	assert(guessImageFormatFromExtension("test.jpeg") == ImageFileFormat.Jpeg);
	assert(guessImageFormatFromExtension("test.JPEG") == ImageFileFormat.Jpeg);
	assert(guessImageFormatFromExtension("test.pcx") == ImageFileFormat.Pcx);
	assert(guessImageFormatFromExtension("test.PCX") == ImageFileFormat.Pcx);
	assert(guessImageFormatFromExtension("test") == ImageFileFormat.Unknown);
	assert(guessImageFormatFromExtension("nonimage.test") == ImageFileFormat.Unknown);
	assert(guessImageFormatFromExtension("jpg") == ImageFileFormat.Unknown); // no extension
}

/// Try to guess image format by first data bytes.
public ImageFileFormat guessImageFormatFromMemory (const(void)[] membuf) @safe {
	enum TargaSign = "TRUEVISION-XFILE.\x00";
	auto buf = cast(const(ubyte)[])membuf;
	if (buf.length == 0) return ImageFileFormat.Unknown;
	// detect file format
	// png
	if (buf.length > 7 && buf[0 .. 7] == [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A])
	{
		return ImageFileFormat.Png;
	}
	// bmp
	if (buf.length > 6 && buf[0 .. 2] == "BM") {
		uint datasize = (cast(const(uint)[])(buf[2 .. 2 + uint.sizeof]))[0];
		if (datasize > 6 && datasize <= buf.length) return ImageFileFormat.Bmp;
	}
	// gif
	if (buf.length > 5 && buf[0 .. 5] == "GIF87" || buf[0 .. 5] == "GIF89")
	{
		return ImageFileFormat.Gif;
	}
	// dds
	if (ddsDetect(membuf)) return ImageFileFormat.Dds;
	// jpg
	try {
		int width, height, components;
		if (detect_jpeg_image_from_memory(buf, width, height, components)) return ImageFileFormat.Jpeg;
	} catch (Exception e) {} // sorry
	// tga (sorry, targas without footer, i don't love you)
	if (buf.length > TargaSign.length+4*2 && cast(const(char)[])(buf[$-TargaSign.length..$]) == TargaSign) {
		// more guesswork
		switch (buf[2]) {
			case 1: case 2: case 3: case 9: case 10: case 11: return ImageFileFormat.Tga;
			default:
		}
	}
	// ok, try to guess targa by validating some header fields
	bool guessTarga () nothrow @safe {
		if (buf.length < 45) return false; // minimal 1x1 tga
		immutable header = (cast(const(TGAHeader)[])(buf[0 .. TGAHeader.sizeof]))[0];
		if (header.image.width.native < 1 || header.image.height.native < 1 || header.image.width.native > 32000 || header.image.height.native > 32000) return false; // arbitrary limit
		immutable uint pixelsize = (header.image.bpp>>3);
		switch (header.imgType) {
			case 2: // truecolor, raw
			case 10: // truecolor, rle
				switch (pixelsize) {
					case 2: case 3: case 4: break;
					default: return false;
				}
				break;
			case 1: // paletted, raw
			case 9: // paletted, rle
				if (pixelsize != 1) return false;
				break;
			case 3: // b/w, raw
			case 11: // b/w, rle
				if (pixelsize != 1 && pixelsize != 2) return false;
				break;
			default: // invalid type
				return false;
		}
		// check for valid colormap
		switch (header.cmapType) {
			case 0:
				if (header.cmap.firstIndex != 0 || header.cmap.size != 0) return 0;
				break;
			case 1:
				if (header.cmap.elementSize != 15 && header.cmap.elementSize != 16 && header.cmap.elementSize != 24 && header.cmap.elementSize != 32) return false;
				if (header.cmap.size == 0) return false;
				break;
			default: // invalid colormap type
				return false;
		}
		if (!header.zeroBits) return false;
		// this *looks* like a tga
		return true;
	}
	if (guessTarga()) return ImageFileFormat.Tga;

	bool guessPcx() nothrow @safe {
		if (buf.length < PCXHeader.sizeof) return false; // we should have at least header
		immutable header = (cast(const(PCXHeader)[])(buf[0 .. PCXHeader.sizeof]))[0];

		// check some header fields
		if (header.manufacturer != 0x0a) return false;
		if (/*header.ver != 0 && header.ver != 2 && header.ver != 3 &&*/ header.ver != 5) return false;
		if (header.encoding != 0 && header.encoding != 1) return false;

		int wdt = header.xmax-header.xmin.native+1;
		int hgt = header.ymax-header.ymin.native+1;

		// arbitrary size limits
		if (wdt < 1 || wdt > 32000) return false;
		if (hgt < 1 || hgt > 32000) return false;

		if (header.bytesperline < wdt) return false;

		// if it's not a 256-color PCX file, and not 24-bit PCX file, gtfo
		bool bpp24 = false;
		if (header.colorplanes == 1) {
			if (header.bitsperpixel != 8 && header.bitsperpixel != 24 && header.bitsperpixel != 32) return false;
			bpp24 = (header.bitsperpixel == 24);
		} else if (header.colorplanes == 3 || header.colorplanes == 4) {
			if (header.bitsperpixel != 8) return false;
			bpp24 = true;
		}

		// additional checks
		if (header.reserved != 0) return false;

		// 8bpp files MUST have palette
		if (!bpp24 && buf.length < PCXHeader.sizeof + 769) return false;

		// it can be pcx
		return true;
	}
	if (guessPcx()) return ImageFileFormat.Pcx;

	// kinda lame svg detection but don't want to parse too much of it here
	if (buf.length > 6 && buf[0] == '<') {
			return ImageFileFormat.Svg;
	}

	// dunno
	return ImageFileFormat.Unknown;
}

@safe unittest {
	import std.file : read;
	assert(guessImageFormatFromMemory(read("testdata/test.png")) == ImageFileFormat.Png);
	assert(guessImageFormatFromMemory(read("testdata/test.gif")) == ImageFileFormat.Gif);
	assert(guessImageFormatFromMemory(read("testdata/test.bmp")) == ImageFileFormat.Bmp);
	assert(guessImageFormatFromMemory(read("testdata/test.jpg")) == ImageFileFormat.Jpeg);
	assert(guessImageFormatFromMemory(read("testdata/test.dds")) == ImageFileFormat.Dds);
	assert(guessImageFormatFromMemory(read("testdata/test.tga")) == ImageFileFormat.Tga);
	assert(guessImageFormatFromMemory(read("testdata/test.svg")) == ImageFileFormat.Svg);
	assert(guessImageFormatFromMemory(read("testdata/test.pcx")) == ImageFileFormat.Pcx);
}


/// Try to guess image format from file name and load that image.
public MemoryImage loadImageFromFile(T:const(char)[]) (T filename) {
	static if (is(T == typeof(null))) {
		throw new PixelmancyException("cannot load image from unnamed file");
	} else {
		final switch (guessImageFormatFromExtension(filename)) {
			case ImageFileFormat.Unknown:
				//throw new PixelmancyException("cannot determine file format from extension");
				import std.stdio;
				static if (is(T == string)) {
					auto fl = File(filename);
				} else {
					auto fl = File(filename.idup);
				}
				auto fsz = fl.size-fl.tell;
				if (fsz < 4) throw new PixelmancyException("cannot determine file format");
				if (fsz > int.max/8) throw new PixelmancyException("image data too big");
				auto data = new ubyte[](cast(uint)fsz);
				scope(exit) { import core.memory : GC; GC.free(data.ptr); } // this should be safe, as image will copy data to it's internal storage
				fl.rawRead(data);
				return loadImageFromMemory(data);
			case ImageFileFormat.Png: static if (is(T == string)) return readPng(filename); else return readPng(filename.idup);
			case ImageFileFormat.Bmp: static if (is(T == string)) return readBmp(filename); else return readBmp(filename.idup);
			case ImageFileFormat.Jpeg: return readJpeg(filename);
			case ImageFileFormat.Gif: throw new PixelmancyException("arsd has no GIF loader yet");
			case ImageFileFormat.Tga: return loadTga(filename);
			case ImageFileFormat.Pcx: return loadPcx(filename);
			case ImageFileFormat.Svg: static if (is(T == string)) return readSvg(filename); else return readSvg(filename.idup);
			case ImageFileFormat.Dds:
				import std.stdio;
				static if (is(T == string)) {
					auto fl = File(filename);
				} else {
					auto fl = File(filename.idup);
				}
				return ddsLoadFromFile(fl);
		}
	}
}


/// Try to guess image format from data and load that image.
public MemoryImage loadImageFromMemory (const(void)[] membuf) {
	final switch (guessImageFormatFromMemory(membuf)) {
		case ImageFileFormat.Unknown: throw new PixelmancyException("cannot determine file format");
		case ImageFileFormat.Png: return imageFromPng(readPng(cast(const(ubyte)[])membuf));
		case ImageFileFormat.Bmp: return readBmp(cast(const(ubyte)[])membuf);
		case ImageFileFormat.Jpeg: return readJpegFromMemory(cast(const(ubyte)[])membuf);
		case ImageFileFormat.Gif: throw new PixelmancyException("arsd has no GIF loader yet");
		case ImageFileFormat.Tga: return loadTga(cast(const(ubyte)[])membuf);
		case ImageFileFormat.Pcx: return loadPcx(cast(const(ubyte)[])membuf);
		case ImageFileFormat.Svg: return readSvg(cast(const(ubyte)[]) membuf);
		case ImageFileFormat.Dds: return ddsLoadFromMemory(membuf);
	}
}
