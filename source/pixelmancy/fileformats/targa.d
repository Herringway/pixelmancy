//ketmar: Adam didn't wrote this, don't blame him!
module pixelmancy.fileformats.targa;

import pixelmancy.colours.formats;
import pixelmancy.fileformats.color;
import pixelmancy.util;

import std.algorithm.comparison;
import std.bitmanip : bitfields;
import std.exception;

class TGALoadException : ImageLoadException {
	mixin basicExceptionCtors;
}

public MemoryImage loadTga(const(char)[] fname) @safe {
	return loadTga(trustedRead(fname));
}
@safe unittest {
	{ // 32-bit
		const tga = loadTga("testdata/test.tga");
		assert(tga[0, 0] == RGBA32(0, 0, 255, 255));
		assert(tga[128, 0] == RGBA32(0, 255, 0, 255));
		assert(tga[0, 128] == RGBA32(255, 0, 0, 255));
		assert(tga[128, 128] == RGBA32(0, 0, 0, 0));
	}
	{ // 32-bit, vertically flipped
		const tga = loadTga("testdata/test-v.tga");
		assert(tga[0, 128] == RGBA32(0, 0, 255, 255));
		assert(tga[128, 128] == RGBA32(0, 255, 0, 255));
		assert(tga[0, 0] == RGBA32(255, 0, 0, 255));
		assert(tga[128, 0] == RGBA32(0, 0, 0, 0));
	}
	{ // 32-bit, horizontally flipped
		const tga = loadTga("testdata/test-h.tga");
		assert(tga[128, 0] == RGBA32(0, 0, 255, 255));
		assert(tga[0, 0] == RGBA32(0, 255, 0, 255));
		assert(tga[128, 128] == RGBA32(255, 0, 0, 255));
		assert(tga[0, 128] == RGBA32(0, 0, 0, 0));
	}
	{ // 32-bit, horizontally and vertically flipped
		const tga = loadTga("testdata/test-hv.tga");
		assert(tga[128, 128] == RGBA32(0, 0, 255, 255));
		assert(tga[0, 128] == RGBA32(0, 255, 0, 255));
		assert(tga[128, 0] == RGBA32(255, 0, 0, 255));
		assert(tga[0, 0] == RGBA32(0, 0, 0, 0));
	}
	{ // 24-bit
		const tga = loadTga("testdata/test-24.tga");
		assert(tga[0, 0] == RGBA32(0, 0, 255, 255));
		assert(tga[128, 0] == RGBA32(0, 255, 0, 255));
		assert(tga[0, 128] == RGBA32(255, 0, 0, 255));
		assert(tga[128, 128] == RGBA32(0, 0, 0, 255));
	}
	{ // 8-bit, paletted colour
		const tga = loadTga("testdata/test-cm8.tga");
		assert(tga[0, 0] == RGBA32(0, 0, 255, 255));
		assert(tga[128, 0] == RGBA32(0, 255, 0, 255));
		assert(tga[0, 128] == RGBA32(255, 0, 0, 255));
		assert(tga[128, 128] == RGBA32(0, 0, 0, 255));
	}
	{ // 8-bit, grayscale
		const tga = loadTga("testdata/test-bm8.tga");
		assert(tga[0, 0] == RGBA32(18, 18, 18, 255));
		assert(tga[128, 0] == RGBA32(182, 182, 182, 255));
		assert(tga[0, 128] == RGBA32(54, 54, 54, 255));
		assert(tga[128, 128] == RGBA32(0, 0, 0, 255));
	}
	{ // 16-bit, grayscale
		const tga = loadTga("testdata/test-bm16.tga");
		assert(tga[0, 0] == RGBA32(18, 18, 18, 255));
		assert(tga[128, 0] == RGBA32(182, 182, 182, 255));
		assert(tga[0, 128] == RGBA32(54, 54, 54, 255));
		assert(tga[128, 128] == RGBA32(0, 0, 0, 255));
	}
}

static struct TGAHeader {
	align(1):
	ubyte idsize;
	ubyte cmapType;
	ImageType imgType;
	ColourMapSpec cmap;
	ImageSpec image;
	enum ImageType : ubyte {
		none = 0,
		colourMapped = 1,
		trueColour = 2,
		grayscale = 3,
		rle = 8,
		colourMappedRLE = colourMapped | rle,
		trueColourRLE = trueColour | rle,
		grayscaleRLE = grayscale | rle,
	}
	static struct Descriptor {
		align(1):
		mixin(bitfields!(
			ubyte, "alpha", 4,
			bool, "xflip", 1,
			bool, "yflip", 1,
			ubyte, "reserved", 2,
		));
	}
	static struct ColourMapSpec {
		align(1):
		LittleEndian!ushort firstIndex;
		LittleEndian!ushort size;
		ubyte elementSize;
	}
	static struct ImageSpec {
		align(1):
		LittleEndian!ushort originX;
		LittleEndian!ushort originY;
		LittleEndian!ushort width;
		LittleEndian!ushort height;
		ubyte bpp;
		Descriptor descriptor;
	}

	auto zeroBits() const => !image.descriptor.reserved;
	auto xflip() const => image.descriptor.xflip;
	auto yflip() const => !image.descriptor.yflip;
}
MemoryImage loadTga(const(ubyte)[] fl) @safe {
	enum expectedSignature = "TRUEVISION-XFILE.\x00";

	static immutable ubyte[32] cmap16 = [0,8,16,25,33,41,49,58,66,74,82,90,99,107,115,123,132,140,148,156,165,173,181,189,197,206,214,222,230,239,247,255];

	static struct ExtFooter {
		align(1):
		LittleEndian!uint extofs;
		LittleEndian!uint devdirofs;
		char[18] sign = expectedSignature;
	}

	static struct Extension {
		align(1):
		LittleEndian!ushort size;
		char[41] author = 0;
		char[324] comments = 0;
		LittleEndian!ushort month, day, year;
		LittleEndian!ushort hour, minute, second;
		char[41] jid = 0;
		LittleEndian!ushort jhours, jmins, jsecs;
		char[41] producer = 0;
		LittleEndian!ushort prodVer;
		ubyte prodSubVer;
		ubyte keyR, keyG, keyB, keyZero;
		LittleEndian!ushort pixratioN, pixratioD;
		LittleEndian!ushort gammaN, gammaD;
		LittleEndian!uint ccofs;
		LittleEndian!uint wtfofs;
		LittleEndian!uint scanlineofs;
		ubyte attrType;
	}

	ExtFooter extfooter;
	uint rleBC, rleDC;
	ubyte[4] rleLast;
	RGBA32[256] cmap;
	void readPixel(bool asRLE, Format)(Format[] pixel) {
		ubyte[] rawBytes = cast(ubyte[])pixel;
		static if (asRLE) {
			if (rleDC > 0) {
				// still counting
				static if (Format.sizeof == 1) {
					rawBytes[0] = rleLast[0];
				}
				else rawBytes[0 .. Format.sizeof] = rleLast[0 .. Format.sizeof];
				--rleDC;
				return;
			}
			if (rleBC > 0) {
				--rleBC;
			} else {
				ubyte b = fl.read!ubyte();
				if (b&0x80) {
					rleDC = (b & 0x7f);
				} else {
					rleBC = (b & 0x7f);
				}
			}
			foreach (immutable idx; 0..Format.sizeof) {
				rleLast[idx] = rawBytes[idx] = fl.read!ubyte();
			}
		} else {
			foreach (immutable idx; 0..Format.sizeof) {
				rawBytes[idx] = fl.read!ubyte();
			}
		}
	}

	// 8 bit color-mapped row
	RGBA32 readColorCM8(bool asRLE)() {
		ubyte[1] pixel;
		readPixel!asRLE(pixel[]);
		return cmap[pixel[0]];
	}

	// 16 bit
	RGBA32 readColorPixel(bool asRLE, T)() {
		T[1] pixel;
		readPixel!asRLE(pixel[]);
		return pixel[0].convert!RGBA32;
	}

	bool detect(const(ubyte)[] fl) {
		if (fl.length < 45) {
			return false; // minimal 1x1 tga
		}
		// try footer
		fl = fl[$ - (4 * 2 + 18) .. $];
		extfooter = fl.read!ExtFooter();
		if (extfooter.sign != expectedSignature) {
			extfooter = extfooter.init;
			return true; // alas, footer is optional
		}
		return true;
	}
	auto orig = fl;

	enforce!TGALoadException(detect(fl), "Not a TGA");
	auto hdr = fl.read!TGAHeader();
	// parse header
	// arbitrary size limits
	enforce!TGALoadException((hdr.image.width > 0) && (hdr.image.width <= 32000), "Invalid width");
	enforce!TGALoadException((hdr.image.height > 0) && (hdr.image.height <= 32000), "Invalid height");
	switch (hdr.image.bpp) {
		case 1: case 2: case 4: case 8: case 15: case 16: case 24: case 32: break;
		default: throw new TGALoadException("Invalid bpp");
	}
	uint bytesPerPixel = ((hdr.image.bpp) >> 3);
	enforce!TGALoadException((bytesPerPixel > 0) && (bytesPerPixel <= 4), "Invalid pixel size");
	bool loadCM = false;
	// get the row reading function
	scope RGBA32 delegate () @safe readColor;
	switch (hdr.imgType) {
		case TGAHeader.ImageType.trueColour:
			switch (bytesPerPixel) {
				case 2: readColor = &readColorPixel!(false, LittleEndian!BGR555); break;
				case 3: readColor = &readColorPixel!(false, BGR24); break;
				case 4: readColor = &readColorPixel!(false, BGRA32); break;
				default: throw new TGALoadException("Invalid pixel size");
			}
			break;
		case TGAHeader.ImageType.trueColourRLE:
			switch (bytesPerPixel) {
				case 2: readColor = &readColorPixel!(true, LittleEndian!BGR555); break;
				case 3: readColor = &readColorPixel!(true, BGR24); break;
				case 4: readColor = &readColorPixel!(true, BGRA32); break;
				default: throw new TGALoadException("Invalid pixel size");
			}
			break;
		case TGAHeader.ImageType.grayscale:
			switch (bytesPerPixel) {
				case 1: readColor = &readColorPixel!(false, Y8); break;
				case 2: readColor = &readColorPixel!(false, LittleEndian!Y16); break;
				default: throw new TGALoadException("Invalid pixel size");
			}
			break;
		case TGAHeader.ImageType.grayscaleRLE:
			switch (bytesPerPixel) {
				case 1: readColor = &readColorPixel!(true, Y8); break;
				case 2: readColor = &readColorPixel!(true, LittleEndian!Y16); break;
				default: throw new TGALoadException("Invalid pixel size");
			}
			break;
		case TGAHeader.ImageType.colourMapped:
			enforce!TGALoadException(bytesPerPixel == 1, "Invalid pixel size");
			loadCM = true;
			readColor = &readColorCM8!false;
			break;
		case TGAHeader.ImageType.colourMappedRLE:
			enforce!TGALoadException(bytesPerPixel == 1, "Invalid pixel size");
			loadCM = true;
			readColor = &readColorCM8!true;
			break;
		default: throw new TGALoadException("Invalid format");
	}
	// check for valid colormap
	switch (hdr.cmapType) {
		case 0:
			enforce!TGALoadException((hdr.cmap.firstIndex == 0) && (hdr.cmap.size == 0), "Invalid colormap type");
			break;
		case 1:
			enforce!TGALoadException(hdr.cmap.elementSize.among(15, 16, 24, 32), "Invalid colormap type");
			enforce!TGALoadException(hdr.cmap.size != 0, "Invalid colormap type");
			break;
		default: throw new TGALoadException("Invalid colormap type");
	}
	enforce!TGALoadException(hdr.zeroBits, "Invalid header");
	void loadColormap() {
		assert(hdr.cmapType == 1, "Invalid TGA colormap type");
		// calculate color map size
		uint colorEntryBytes = 0;
		switch (hdr.cmap.elementSize) {
			case 15:
			case 16: colorEntryBytes = 2; break;
			case 24: colorEntryBytes = 3; break;
			case 32: colorEntryBytes = 4; break;
			default: throw new TGALoadException("Invalid colormap type");
		}
		auto colourMapBytes = fl[0 .. colorEntryBytes*hdr.cmap.size];
		enforce!TGALoadException(colourMapBytes.length > 0, "Invalid colormap type");
		fl = fl[colourMapBytes.length .. $];
		// if we're going to use the color map, read it in.
		if (loadCM) {
			enforce!TGALoadException(hdr.cmap.firstIndex + hdr.cmap.size <= 256, "Invalid colormap type");
			foreach (immutable n; 0..hdr.cmap.size) {
				switch (colorEntryBytes) {
					case 2:
						ushort v = colourMapBytes.read!(LittleEndian!ushort)().native;
						cmap[n].blue = cmap16[v&0x1f];
						cmap[n].green = cmap16[(v>>5)&0x1f];
						cmap[n].red = cmap16[(v>>10)&0x1f];
						break;
					case 3:
						cmap[n] = colourMapBytes.read!(BGR24)().convert!RGBA32();
						break;
					case 4:
						cmap[n] = colourMapBytes.read!(BGRA32)().convert!RGBA32();
						break;
					default: throw new TGALoadException("Invalid colormap type");
				}
			}
		}
	}

	// now load the data
	fl = fl[hdr.idsize .. $];
	if (hdr.cmapType != 0) {
		loadColormap();
	}

	// we don't know if alpha is premultiplied yet
	bool hasAlpha = (bytesPerPixel == 4);
	bool validAlpha = hasAlpha;

	auto tcimg = new TrueColorImage(hdr.image.width, hdr.image.height);

	{
		// read image data
		size_t indexY = hdr.yflip ? (hdr.image.height - 1) : 0;
		foreach (y; 0..hdr.image.height) {
			size_t indexX = hdr.xflip ? (hdr.image.width - 1) : 0;
			foreach (x; 0 .. hdr.image.width) {
				tcimg.colours[indexX, indexY] = readColor();
				indexX += hdr.xflip ? -1 : 1;
			}
			indexY += hdr.yflip ? -1 : 1;
		}
	}

	if (hasAlpha) {
		if (extfooter.extofs != 0) {
			Extension ext;
			fl = orig[extfooter.extofs .. $];
			ext = fl.read!Extension();
			// some idiotic writers set 494 instead 495, tolerate that
			enforce!TGALoadException(ext.size >= 494, "Invalid extension record");
			if (ext.attrType == 4) {
				// premultiplied alpha
				foreach (ref RGBA32 clr; tcimg.colours[]) {
					if (clr.alpha != 0) {
						clr.red = cast(ubyte)min(255, clr.red*255/clr.alpha);
						clr.green = cast(ubyte)min(255, clr.green*255/clr.alpha);
						clr.blue = cast(ubyte)min(255, clr.blue*255/clr.alpha);
					}
				}
			} else if (ext.attrType != 3) {
				validAlpha = false;
			}
		} else {
			// some writers sets all alphas to zero, check for that
			validAlpha = false;
			foreach (ref RGBA32 clr; tcimg.colours[]) {
				if (clr.alpha != 0) {
					validAlpha = true; break;
				}
			}
		}
		if (!validAlpha) {
			foreach (ref RGBA32 clr; tcimg.colours[]) {
				clr.alpha = 255;
			}
		}
	}
	return tcimg;
}
