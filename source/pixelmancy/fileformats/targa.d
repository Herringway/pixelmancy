//ketmar: Adam didn't wrote this, don't blame him!
module pixelmancy.fileformats.targa;

import pixelmancy.colours.formats;
import pixelmancy.fileformats.color;
import pixelmancy.util;
import std.algorithm.comparison : min;


// ////////////////////////////////////////////////////////////////////////// //
deprecated alias loadTgaMem = loadTga;

public MemoryImage loadTga(const(char)[] fname) @safe {
	static const(ubyte)[] trustedRead(const(char)[] fname) @trusted {
		import std.file : read;
		return cast(const(ubyte)[])read(fname);
	}
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
	ubyte imgType;
	LittleEndian!ushort cmapFirstIdx;
	LittleEndian!ushort cmapSize;
	ubyte cmapElementSize;
	LittleEndian!ushort originX;
	LittleEndian!ushort originY;
	LittleEndian!ushort width;
	LittleEndian!ushort height;
	ubyte bpp;
	ubyte imgdsc;

	bool zeroBits () const pure nothrow @safe @nogc { return ((imgdsc&0xc0) == 0); }
	bool xflip () const pure nothrow @safe @nogc { return ((imgdsc&0b010000) != 0); }
	bool yflip () const pure nothrow @safe @nogc { return ((imgdsc&0b100000) == 0); }
}
private MemoryImage loadTga(const(ubyte)[] fl) @safe {
	enum TGAFILESIGNATURE = "TRUEVISION-XFILE.\x00";

	static immutable ubyte[32] cmap16 = [0,8,16,25,33,41,49,58,66,74,82,90,99,107,115,123,132,140,148,156,165,173,181,189,197,206,214,222,230,239,247,255];

	static struct ExtFooter {
		align(1):
		uint extofs;
		uint devdirofs;
		char[18] sign=0;
	}

	static struct Extension {
		align(1):
		LittleEndian!ushort size;
		char[41] author=0;
		char[324] comments=0;
		LittleEndian!ushort month, day, year;
		LittleEndian!ushort hour, minute, second;
		char[41] jid=0;
		LittleEndian!ushort jhours, jmins, jsecs;
		char[41] producer=0;
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
	alias ByteReadFunction = ubyte delegate() @safe;
	void readPixel(bool asRLE, uint bytesPerPixel) (ubyte[] pixel, scope ByteReadFunction readByte) {
		static if (asRLE) {
			if (rleDC > 0) {
				// still counting
				static if (bytesPerPixel == 1) pixel[0] = rleLast[0];
				else pixel[0..bytesPerPixel] = rleLast[0..bytesPerPixel];
				--rleDC;
				return;
			}
			if (rleBC > 0) {
				--rleBC;
			} else {
				ubyte b = readByte();
				if (b&0x80) rleDC = (b&0x7f); else rleBC = (b&0x7f);
			}
			foreach (immutable idx; 0..bytesPerPixel) rleLast[idx] = pixel[idx] = readByte();
		} else {
			foreach (immutable idx; 0..bytesPerPixel) pixel[idx] = readByte();
		}
	}

	// 8 bit color-mapped row
	RGBA32 readColorCM8(bool asRLE)(scope ByteReadFunction readByte) {
		ubyte[1] pixel;
		readPixel!(asRLE, 1)(pixel[], readByte);
		return cmap[pixel[0]];
	}

	// 8 bit greyscale
	RGBA32 readColorBM8(bool asRLE)(scope ByteReadFunction readByte) {
		ubyte[1] pixel;
		readPixel!(asRLE, 1)(pixel[], readByte);
		return RGBA32(pixel[0], pixel[0], pixel[0]);
	}

	// 16 bit greyscale
	RGBA32 readColorBM16(bool asRLE)(scope ByteReadFunction readByte) {
		ubyte[2] pixel;
		readPixel!(asRLE, 2)(pixel[], readByte);
		immutable ubyte v = cast(ubyte)(((pixel[1] << 8)) >> 8);
		return RGBA32(v, v, v);
	}

	// 16 bit
	RGBA32 readColor16(bool asRLE)(scope ByteReadFunction readByte) {
		ubyte[2] pixel;
		readPixel!(asRLE, 2)(pixel[], readByte);
		immutable v = pixel[0] + (pixel[1] << 8);
		return RGBA32(cmap16[(v >> 10) & 0x1f], cmap16[(v >> 5) & 0x1f], cmap16[v & 0x1f]);
	}

	// 24 bit or 32 bit
	RGBA32 readColorTrue(bool asRLE, uint bytesPerPixel)(scope ByteReadFunction readByte) {
		ubyte[bytesPerPixel] pixel;
		readPixel!(asRLE, bytesPerPixel)(pixel[], readByte);
		ubyte r = pixel[2];
		ubyte g = pixel[1];
		ubyte b = pixel[0];
		ubyte a = 255;
		static if (bytesPerPixel == 4) {
			a = pixel[3];
		}
		return RGBA32(r, g, b, a);
	}

	bool detect(const(ubyte)[] fl) {
		if (fl.length < 45) return false; // minimal 1x1 tga
		// try footer
		fl = fl[$ - (4 * 2 + 18) .. $];
		extfooter = fl.read!ExtFooter();
		if (extfooter.sign != TGAFILESIGNATURE) {
			extfooter = extfooter.init;
			return true; // alas, footer is optional
		}
		return true;
	}
	auto orig = fl;

	if (!detect(fl)) throw new Exception("not a TGA");
	auto hdr = fl.read!TGAHeader();
	// parse header
	// arbitrary size limits
	if (hdr.width == 0 || hdr.width > 32000) throw new Exception("invalid tga width");
	if (hdr.height == 0 || hdr.height > 32000) throw new Exception("invalid tga height");
	switch (hdr.bpp) {
		case 1: case 2: case 4: case 8: case 15: case 16: case 24: case 32: break;
		default: throw new Exception("invalid tga bpp");
	}
	uint bytesPerPixel = ((hdr.bpp)>>3);
	if (bytesPerPixel == 0 || bytesPerPixel > 4) throw new Exception("invalid tga pixel size");
	bool loadCM = false;
	// get the row reading function
	ubyte readByte () { return fl.read!ubyte(); }
	scope RGBA32 delegate (scope ByteReadFunction readByte) @safe readColor;
	switch (hdr.imgType) {
		case 2: // true color, no rle
			switch (bytesPerPixel) {
				case 2: readColor = &readColor16!false; break;
				case 3: readColor = &readColorTrue!(false, 3); break;
				case 4: readColor = &readColorTrue!(false, 4); break;
				default: throw new Exception("invalid tga pixel size");
			}
			break;
		case 10: // true color, rle
			switch (bytesPerPixel) {
				case 2: readColor = &readColor16!true; break;
				case 3: readColor = &readColorTrue!(true, 3); break;
				case 4: readColor = &readColorTrue!(true, 4); break;
				default: throw new Exception("invalid tga pixel size");
			}
			break;
		case 3: // black&white, no rle
			switch (bytesPerPixel) {
				case 1: readColor = &readColorBM8!false; break;
				case 2: readColor = &readColorBM16!false; break;
				default: throw new Exception("invalid tga pixel size");
			}
			break;
		case 11: // black&white, rle
			switch (bytesPerPixel) {
				case 1: readColor = &readColorBM8!true; break;
				case 2: readColor = &readColorBM16!true; break;
				default: throw new Exception("invalid tga pixel size");
			}
			break;
		case 1: // colormap, no rle
			if (bytesPerPixel != 1) throw new Exception("invalid tga pixel size");
			loadCM = true;
			readColor = &readColorCM8!false;
			break;
		case 9: // colormap, rle
			if (bytesPerPixel != 1) throw new Exception("invalid tga pixel size");
			loadCM = true;
			readColor = &readColorCM8!true;
			break;
		default: throw new Exception("invalid tga format");
	}
	// check for valid colormap
	switch (hdr.cmapType) {
		case 0:
			if (hdr.cmapFirstIdx != 0 || hdr.cmapSize != 0) throw new Exception("invalid tga colormap type");
			break;
		case 1:
			if (hdr.cmapElementSize != 15 && hdr.cmapElementSize != 16 && hdr.cmapElementSize != 24 && hdr.cmapElementSize != 32) throw new Exception("invalid tga colormap type");
			if (hdr.cmapSize == 0) throw new Exception("invalid tga colormap type");
			break;
		default: throw new Exception("invalid tga colormap type");
	}
	if (!hdr.zeroBits) throw new Exception("invalid tga header");
	void loadColormap () {
		if (hdr.cmapType != 1) throw new Exception("invalid tga colormap type");
		// calculate color map size
		uint colorEntryBytes = 0;
		switch (hdr.cmapElementSize) {
			case 15:
			case 16: colorEntryBytes = 2; break;
			case 24: colorEntryBytes = 3; break;
			case 32: colorEntryBytes = 4; break;
			default: throw new Exception("invalid tga colormap type");
		}
		uint colorMapBytes = colorEntryBytes*hdr.cmapSize;
		if (colorMapBytes == 0) throw new Exception("invalid tga colormap type");
		// if we're going to use the color map, read it in.
		if (loadCM) {
			if (hdr.cmapFirstIdx+hdr.cmapSize > 256) throw new Exception("invalid tga colormap type");
			ubyte readCMB () {
				if (colorMapBytes == 0) return 0;
				--colorMapBytes;
				return readByte;
			}
			cmap[] = RGBA32(0, 0, 0, 255);
			auto cmp = cmap[];
			foreach (immutable n; 0..hdr.cmapSize) {
				switch (colorEntryBytes) {
					case 2:
						uint v = readCMB();
						v |= readCMB()<<8;
						cmp[0].blue = cmap16[v&0x1f];
						cmp[0].green = cmap16[(v>>5)&0x1f];
						cmp[0].red = cmap16[(v>>10)&0x1f];
						break;
					case 3:
						cmp[0].blue = readCMB();
						cmp[0].green = readCMB();
						cmp[0].red = readCMB();
						break;
					case 4:
						cmp[0].blue = readCMB();
						cmp[0].green = readCMB();
						cmp[0].red = readCMB();
						cmp[0].alpha = readCMB();
						break;
					default: throw new Exception("invalid tga colormap type");
				}
				cmp = cmp[1 .. $];
			}
		} else {
			// skip colormap
			fl = fl[colorMapBytes .. $];
		}
	}

	// now load the data
	fl = fl[hdr.idsize .. $];
	if (hdr.cmapType != 0) loadColormap();

	// we don't know if alpha is premultiplied yet
	bool hasAlpha = (bytesPerPixel == 4);
	bool validAlpha = hasAlpha;
	bool premult = false;

	auto tcimg = new TrueColorImage(hdr.width, hdr.height);

	{
		// read image data
		size_t indexY = hdr.yflip ? (hdr.height - 1) : 0;
		foreach (y; 0..hdr.height) {
			size_t indexX = hdr.xflip ? (hdr.width - 1) : 0;
			foreach (x; 0 .. hdr.width) {
				tcimg.colours[indexX, indexY] = readColor(&readByte);
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
			if (ext.size < 494) throw new Exception("invalid tga extension record");
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
			foreach (ref RGBA32 clr; tcimg.colours[]) if (clr.alpha != 0) { validAlpha = true; break; }
		}
		if (!validAlpha) foreach (ref RGBA32 clr; tcimg.colours[]) clr.alpha = 255;
	}
	return tcimg;
}
