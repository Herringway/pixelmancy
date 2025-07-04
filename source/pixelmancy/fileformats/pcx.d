//ketmar: Adam didn't wrote this, don't blame him!
//TODO: other bpp formats besides 8 and 24
module pixelmancy.fileformats.pcx;

import pixelmancy.colours.formats;
import pixelmancy.fileformats.color;
import pixelmancy.util;


// ////////////////////////////////////////////////////////////////////////// //
alias loadPcxMem = loadPcx;

public MemoryImage loadPcx(const(char)[] fname) @safe {
	static const(ubyte)[] trustedRead(const(char)[] fname) @trusted {
		import std.file : read;
		return cast(const(ubyte)[])read(fname);
	}
	return loadPcx(trustedRead(fname));
}

@safe unittest {
	{
		const pcx = loadPcx("testdata/test.pcx");
		assert(pcx[0, 0] == RGBA32(0, 0, 255, 255));
		assert(pcx[128, 0] == RGBA32(0, 255, 0, 255));
		assert(pcx[0, 128] == RGBA32(255, 0, 0, 255));
		assert(pcx[128, 128] == RGBA32(0, 0, 0, 0));
	}
	{
		const pcx = loadPcx("testdata/test8.pcx");
		assert(pcx[0, 0] == RGBA32(0, 0, 255, 255));
		assert(pcx[128, 0] == RGBA32(0, 255, 0, 255));
		assert(pcx[0, 128] == RGBA32(255, 0, 0, 255));
		assert(pcx[128, 128] == RGBA32(0, 0, 0, 255));
	}
}

// PCX file header
struct PCXHeader {
	align(1):
	ubyte manufacturer; // 0x0a --signifies a PCX file
	ubyte ver; // version 5 is what we look for
	ubyte encoding; // when 1, it's RLE encoding (only type as of yet)
	ubyte bitsperpixel; // how many bits to represent 1 pixel
	LittleEndian!ushort xmin, ymin, xmax, ymax; // dimensions of window (really unsigned?)
	LittleEndian!ushort hdpi, vdpi; // device resolution (horizontal, vertical)
	ubyte[16*3] colormap; // 16-color palette
	ubyte reserved;
	ubyte colorplanes; // number of color planes
	LittleEndian!ushort bytesperline; // number of bytes per line (per color plane)
	LittleEndian!ushort palettetype; // 1 = color,2 = grayscale (unused in v.5+)
	ubyte[58] filler; // used to fill-out 128 byte header (useless)
}

MemoryImage loadPcx(const(ubyte)[] fl) @safe {
	// we should have at least header
	if (fl.length < PCXHeader.sizeof + 1) throw new Exception("invalid pcx file size");

	const hdr = fl.read!PCXHeader();

	// check some header fields
	if (hdr.manufacturer != 0x0a) throw new Exception("invalid pcx manufacturer");
	if (/*header.ver != 0 && header.ver != 2 && header.ver != 3 &&*/ hdr.ver != 5) throw new Exception("invalid pcx version");
	if (hdr.encoding != 0 && hdr.encoding != 1) throw new Exception("invalid pcx compresstion");

	int wdt = hdr.xmax-hdr.xmin+1;
	int hgt = hdr.ymax-hdr.ymin+1;

	// arbitrary size limits
	if (wdt < 1 || wdt > 32000) throw new Exception("invalid pcx width");
	if (hgt < 1 || hgt > 32000) throw new Exception("invalid pcx height");

	if (hdr.bytesperline < wdt) throw new Exception("invalid pcx hdr");

	// if it's not a 256-color PCX file, and not 24-bit PCX file, gtfo
	bool bpp24 = false;
	bool hasAlpha = false;
	if (hdr.colorplanes == 1) {
		if (hdr.bitsperpixel != 8 && hdr.bitsperpixel != 24 && hdr.bitsperpixel != 32) throw new Exception("invalid pcx bpp");
		bpp24 = (hdr.bitsperpixel == 24);
		hasAlpha = (hdr.bitsperpixel == 32);
	} else if (hdr.colorplanes == 3 || hdr.colorplanes == 4) {
		if (hdr.bitsperpixel != 8) throw new Exception("invalid pcx bpp");
		bpp24 = true;
		hasAlpha = (hdr.colorplanes == 4);
	}

	// additional checks
	if (hdr.reserved != 0) throw new Exception("invalid pcx hdr");

	// 8bpp files MUST have palette
	if (!bpp24 && fl.length < 1 + 769) throw new Exception("invalid pcx file size");

	void readLine (ubyte[] line) {
		foreach (immutable p; 0..hdr.colorplanes) {
			int count = 0;
			ubyte b;
			foreach (immutable n; 0..hdr.bytesperline) {
				if (count == 0) {
					// read next byte, do RLE decompression by the way
					b = fl.read!ubyte();
					if (hdr.encoding) {
						if ((b&0xc0) == 0xc0) {
							count = b&0x3f;
							if (count == 0) throw new Exception("invalid pcx RLE data");
							b = fl.read!ubyte();
						} else {
							count = 1;
						}
					} else {
						count = 1;
					}
				}
				assert(count > 0);
				line[n] = b;
				--count;
			}
			// allow excessive counts, why not?
			line = line[hdr.bytesperline.native .. $];
		}
	}

	int lsize = hdr.bytesperline*hdr.colorplanes;
	if (!bpp24 && lsize < 768) lsize = 768; // so we can use it as palette buffer
	auto line = new ubyte[](lsize);

	IndexedImage iimg;
	TrueColorImage timg;

	if (!bpp24) {
		iimg = new IndexedImage(wdt, hgt);
	} else {
		timg = new TrueColorImage(wdt, hgt);
	}

	foreach (immutable y; 0..hgt) {
		readLine(line);
		if (!bpp24) {
			// 8bpp, with palette
			iimg.data[0 .. $, y] = line[0 .. wdt];
		} else {
			// 24bpp
			auto src = line;
			if (hdr.colorplanes != 1) {
				// planar
				foreach (immutable x; 0..wdt) {
					const red = src[0];
					const green = src[hdr.bytesperline];
					const blue = src[hdr.bytesperline*2];
					ubyte alpha = 255;
					if (hasAlpha) {
						alpha = src[hdr.bytesperline*3];
					}
					timg.colours[x, y] = RGBA32(red, green, blue, alpha);
					src = src[1 .. $];
				}
			} else {
				// flat
				foreach (immutable x; 0..wdt) {
					const red = src.read!ubyte;
					const green = src.read!ubyte;
					const blue = src.read!ubyte;
					ubyte alpha = 255;
					if (hasAlpha) {
						alpha = src.read!ubyte;
					}
					timg.colours[x, y] = RGBA32(red, green, blue, alpha);
				}
			}
		}
	}

	// read palette
	if (!bpp24) {
		fl = fl[$ - 769 .. $];
		if (fl.read!ubyte != 12) throw new Exception("invalid pcx palette");
		// it is guaranteed to have at least 768 bytes in `line`
		line[0 .. 768] = fl[0 .. 768];
		if (iimg.palette.length < 256) iimg.palette.length = 256;
		foreach (immutable cidx; 0..256) {
			/* nope, it is not in VGA format
			// transform [0..63] palette to [0..255]
			int r = line[cidx*3+0]*255/63;
			int g = line[cidx*3+1]*255/63;
			int b = line[cidx*3+2]*255/63;
			iimg.palette[cidx] = Color(r, g, b, 255);
			*/
			iimg.palette[cidx] = RGBA32(line[cidx*3+0], line[cidx*3+1], line[cidx*3+2], 255);
		}
		return iimg;
	} else {
		return timg;
	}
}
