// DDS decoders
// Based on code from Nvidia's DDS example:
// http://www.nvidia.com/object/dxtc_decompression_code.html
//
// Copyright (c) 2003 Randy Reddig
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this list
// of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice, this
// list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// Neither the names of the copyright holders nor the names of its contributors may
// be used to endorse or promote products derived from this software without
// specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
// ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// D port and further changes by Ketmar // Invisible Vector
module pixelmancy.fileformats.dds;

import pixelmancy.colours;
import pixelmancy.fileformats.color : TrueColorImage;
import pixelmancy.util;
import std.algorithm.comparison : min;
import std.exception;
import std.format;

class DDSLoadException : ImageLoadException {
	mixin basicExceptionCtors;
}
class DDSSaveException : ImageSaveException {
	mixin basicExceptionCtors;
}

// ////////////////////////////////////////////////////////////////////////// //
public bool ddsDetect (const(ubyte)[] buf) @safe {
	int _;
	return ddsDetect(buf, _, _);
}
public bool ddsDetect (const(ubyte)[] buf, out int width, out int height) @safe {
	if (buf.length < 128) return false;
	auto data = cast(const(ubyte)[])buf;

	uint getUInt (uint ofs) {
		if (ofs >= data.length) return uint.max;
		if (data.length-ofs < 4) return uint.max;
		return data[ofs]|(data[ofs+1]<<8)|(data[ofs+2]<<16)|(data[ofs+3]<<24);
	}

	// signature
	if (data[0] != 'D' || data[1] != 'D' || data[2] != 'S' || data[3] != ' ') return false;
	// header size check
	if (getUInt(4) != 124) return false;

	int w = getUInt(4*4);
	int h = getUInt(3*4);
	// arbitrary limits
	if (w < 1 || h < 1 || w > 65500 || h > 65500) return false;
	width = w;
	height = h;

	// check pixel format
	if (getUInt(76) < 8) return false; // size
	immutable flags = getUInt(80);
	if (flags&DDS_FOURCC) {
		// DXTn
		if (data[84+0] != 'D' || data[84+1] != 'X' || data[84+2] != 'T') return false;
		if (data[84+3] < '1' || data[84+3] > '5') return false;
	} else if (flags == DDS_RGB || flags == DDS_RGBA) {
		immutable bitcount = getUInt(88);
		if (bitcount != 24 && bitcount != 32) return false;
		// ARGB8888
		//if (data[84+0] == 0 || data[84+1] == 0 || data[84+2] == 0 || data[84+3] == 0) return true;
	}
	return true;
}


// ////////////////////////////////////////////////////////////////////////// //
public TrueColorImage ddsLoadFromMemory (const(ubyte)[] buf) @safe {
	int w, h;
	enforce!DDSLoadException(ddsDetect(buf, w, h), "Invalid header");

	const(ddsBuffer_t)[] dds = cast(const(ddsBuffer_t)[])buf[0 .. ddsBuffer_t.sizeof];

	auto tc = new TrueColorImage(w, h);

	DDSDecompress(dds[0], tc.colours[], buf[ddsBuffer_t.data.offsetof .. $]);

	return tc;
}

public TrueColorImage ddsLoadFromFile(const(char)[] filename) @safe {
	return ddsLoadFromMemory(trustedRead(filename));
}

@safe unittest {
	{ // DXT1
		const dds = ddsLoadFromFile("testdata/test-dxt1.dds");
		assert(dds[0, 0] == RGBA32(0, 0, 255, 255));
		assert(dds[128, 0] == RGBA32(0, 255, 0, 255));
		assert(dds[0, 128] == RGBA32(255, 0, 0, 255));
		assert(dds[128, 128] == RGBA32(0, 0, 0, 255)); // no transparency
	}
	{ // DXT2
		const dds = ddsLoadFromFile("testdata/test-dxt2.dds");
		assert(dds[0, 0] == RGBA32(0, 0, 255, 255));
		assert(dds[128, 0] == RGBA32(0, 255, 0, 255));
		assert(dds[0, 128] == RGBA32(255, 0, 0, 255));
		assert(dds[128, 128] == RGBA32(0, 0, 0, 0));
	}
	{ // DXT3
		const dds = ddsLoadFromFile("testdata/test-dxt3.dds");
		assert(dds[0, 0] == RGBA32(0, 0, 255, 255));
		assert(dds[128, 0] == RGBA32(0, 255, 0, 255));
		assert(dds[0, 128] == RGBA32(255, 0, 0, 255));
		assert(dds[128, 128] == RGBA32(0, 0, 0, 0));
	}
	{ // DXT4
		const dds = ddsLoadFromFile("testdata/test-dxt4.dds");
		assert(dds[0, 0] == RGBA32(0, 0, 255, 255));
		assert(dds[128, 0] == RGBA32(0, 255, 0, 255));
		assert(dds[0, 128] == RGBA32(255, 0, 0, 255));
		assert(dds[128, 128] == RGBA32(0, 0, 0, 0));
	}
	{ // DXT5
		const dds = ddsLoadFromFile("testdata/test-dxt5.dds");
		assert(dds[0, 0] == RGBA32(0, 0, 255, 255));
		assert(dds[128, 0] == RGBA32(0, 255, 0, 255));
		assert(dds[0, 128] == RGBA32(255, 0, 0, 255));
		assert(dds[0, 255] == RGBA32(255, 0, 0, 255));
		assert(dds[128, 128] == RGBA32(0, 0, 0, 0));
		assert(dds[255, 255] == RGBA32(0, 0, 0, 0));
	}
	{ // ARGB8888
		const dds = ddsLoadFromFile("testdata/test-argb8888.dds");
		assert(dds[0, 0] == RGBA32(0, 0, 255, 255));
		assert(dds[128, 0] == RGBA32(0, 255, 0, 255));
		assert(dds[0, 128] == RGBA32(255, 0, 0, 255));
		assert(dds[128, 128] == RGBA32(0, 0, 0, 0));
	}
	{ // RGB888
		const dds = ddsLoadFromFile("testdata/test-rgb888.dds");
		assert(dds[0, 0] == RGBA32(0, 0, 255, 255));
		assert(dds[128, 0] == RGBA32(0, 255, 0, 255));
		assert(dds[0, 128] == RGBA32(255, 0, 0, 255));
		assert(dds[128, 128] == RGBA32(0, 0, 0, 255)); // no transparency
	}
}


// ////////////////////////////////////////////////////////////////////////// //
private:

// dds definition
enum DDSPixelFormat {
	Unknown,
	RGB888,
	ARGB8888,
	DXT1,
	DXT2,
	DXT3,
	DXT4,
	DXT5,
}


// 16bpp stuff
enum DDS_LOW_5 = 0x001F;
enum DDS_MID_6 = 0x07E0;
enum DDS_HIGH_5 = 0xF800;
enum DDS_MID_555 = 0x03E0;
enum DDS_HI_555 = 0x7C00;

enum DDS_FOURCC = 0x00000004U;
enum DDS_RGB = 0x00000040U;
enum DDS_RGBA = 0x00000041U;
enum DDS_DEPTH = 0x00800000U;

enum DDS_COMPLEX = 0x00000008U;
enum DDS_CUBEMAP = 0x00000200U;
enum DDS_VOLUME = 0x00200000U;


// structures
align(1) struct ddsColorKey_t {
align(1):
	LittleEndian!uint colorSpaceLowValue;
	LittleEndian!uint colorSpaceHighValue;
}


align(1) struct ddsCaps_t {
align(1):
	LittleEndian!uint caps1;
	LittleEndian!uint caps2;
	LittleEndian!uint caps3;
	LittleEndian!uint caps4;
}


align(1) struct ddsMultiSampleCaps_t {
align(1):
	LittleEndian!ushort flipMSTypes;
	LittleEndian!ushort bltMSTypes;
}


align(1) struct ddsPixelFormat_t {
align(1):
	LittleEndian!uint size;
	LittleEndian!uint flags;
	char[4] fourCC;
	union {
		LittleEndian!uint rgbBitCount;
		LittleEndian!uint yuvBitCount;
		LittleEndian!uint zBufferBitDepth;
		LittleEndian!uint alphaBitDepth;
		LittleEndian!uint luminanceBitCount;
		LittleEndian!uint bumpBitCount;
		LittleEndian!uint privateFormatBitCount;
	}
	union {
		LittleEndian!uint rBitMask;
		LittleEndian!uint yBitMask;
		LittleEndian!uint stencilBitDepth;
		LittleEndian!uint luminanceBitMask;
		LittleEndian!uint bumpDuBitMask;
		LittleEndian!uint operations;
	}
	union {
		LittleEndian!uint gBitMask;
		LittleEndian!uint uBitMask;
		LittleEndian!uint zBitMask;
		LittleEndian!uint bumpDvBitMask;
		ddsMultiSampleCaps_t multiSampleCaps;
	}
	union {
		LittleEndian!uint bBitMask;
		LittleEndian!uint vBitMask;
		LittleEndian!uint stencilBitMask;
		LittleEndian!uint bumpLuminanceBitMask;
	}
	union {
		LittleEndian!uint rgbAlphaBitMask;
		LittleEndian!uint yuvAlphaBitMask;
		LittleEndian!uint luminanceAlphaBitMask;
		LittleEndian!uint rgbZBitMask;
		LittleEndian!uint yuvZBitMask;
	}
}
//pragma(msg, ddsPixelFormat_t.sizeof);


align(1) struct ddsBuffer_t {
align(1):
	// magic: 'dds '
	char[4] magic;

	// directdraw surface
	LittleEndian!uint size;
	LittleEndian!uint flags;
	LittleEndian!uint height;
	LittleEndian!uint width;
	union {
		LittleEndian!int pitch;
		LittleEndian!uint linearSize;
	}
	LittleEndian!uint backBufferCount;
	LittleEndian!uint mipMapCount;
	LittleEndian!uint[11] reserved;
	union {
		ddsPixelFormat_t pixelFormat;
		LittleEndian!uint fvf;
	}
	ddsCaps_t ddsCaps;
	LittleEndian!uint textureStage;

	// data (Varying size)
	ubyte[0] data;
}


align(1) union DDSBlock {
	ddsColorBlock_t colorBlock;
	ddsAlphaBlockExplicit_t alphaBlockExplicit;
	ddsAlphaBlock3BitLinear_t alphaBlock3BitLinear;
}
align(1) struct ddsColorBlock_t {
align(1):
	LittleEndian!ushort[2] colors;
	ubyte[4] row;
}
static assert(ddsColorBlock_t.sizeof == 8);


align(1) struct ddsAlphaBlockExplicit_t {
align(1):
	LittleEndian!ushort[4] row;
}
static assert(ddsAlphaBlockExplicit_t.sizeof == 8);


align(1) struct ddsAlphaBlock3BitLinear_t {
align(1):
	ubyte alpha0;
	ubyte alpha1;
	ubyte[6] stuff;
}
static assert(ddsAlphaBlock3BitLinear_t.sizeof == 8);


// ////////////////////////////////////////////////////////////////////////// //

// extracts relevant info from a dds texture, returns `true` on success
/*public*/ void DDSGetInfo (ref const(ddsBuffer_t) dds, out int width, out int height, out DDSPixelFormat pf) @safe {
	// test dds header
	enforce!DDSLoadException(dds.magic == "DDS ", "Missing magic");
	enforce!DDSLoadException(dds.size == 124, "Invalid size");
	// arbitrary limits
	enforce!DDSLoadException(dds.width >= 1 && dds.width < 65535, "Invalid width");
	enforce!DDSLoadException(dds.height >= 1 && dds.height < 65535, "Invalid height");

	// extract width and height
	width = dds.width;
	height = dds.height;

	// get pixel format
	DDSDecodePixelFormat(dds, pf);
}


// decompresses a dds texture into an rgba image buffer, returns 0 on success
/*public*/ void DDSDecompress (ref const(ddsBuffer_t) dds, RGBA32[] pixels, const(ubyte)[] fileData) @safe {
	int width, height;
	DDSPixelFormat pf;

	// get dds info
	DDSGetInfo(dds, width, height, pf);
	enforce!DDSLoadException(pixels.length >= width*height, "Buffer too small");

	// decompress
	final switch (pf) {
		// FIXME: support other [a]rgb formats
		case DDSPixelFormat.RGB888:
			DDSDecompressRGB888(dds, fileData, width, height, pixels);
			break;
		case DDSPixelFormat.ARGB8888:
			DDSDecompressARGB8888(dds, fileData, width, height, pixels);
			break;
		case DDSPixelFormat.DXT1:
			DDSDecompressDXT1(dds, fileData, width, height, pixels);
			break;
		case DDSPixelFormat.DXT2:
			DDSDecompressDXT2(dds, fileData, width, height, pixels);
			break;
		case DDSPixelFormat.DXT3:
			DDSDecompressDXT3(dds, fileData, width, height, pixels);
			break;
		case DDSPixelFormat.DXT4:
			DDSDecompressDXT4(dds, fileData, width, height, pixels);
			break;
		case DDSPixelFormat.DXT5:
			DDSDecompressDXT5(dds, fileData, width, height, pixels);
			break;
		case DDSPixelFormat.Unknown:
			throw new DDSLoadException(format!"Unknown format %s"(cast(uint)pf));
	}
}


// ////////////////////////////////////////////////////////////////////////// //
private:

// determines which pixel format the dds texture is in
private void DDSDecodePixelFormat (ref const(ddsBuffer_t) dds, out DDSPixelFormat pf) @safe {
	enforce!DDSLoadException(dds.pixelFormat.size >= 8, "Invalid pixel format size");

	if (dds.pixelFormat.flags&DDS_FOURCC) {
		// DXTn
		if (dds.pixelFormat.fourCC == "DXT1") pf = DDSPixelFormat.DXT1;
		else if (dds.pixelFormat.fourCC == "DXT2") pf = DDSPixelFormat.DXT2;
		else if (dds.pixelFormat.fourCC == "DXT3") pf = DDSPixelFormat.DXT3;
		else if (dds.pixelFormat.fourCC == "DXT4") pf = DDSPixelFormat.DXT4;
		else if (dds.pixelFormat.fourCC == "DXT5") pf = DDSPixelFormat.DXT5;
		else throw new DDSLoadException("Unknown format");
	} else if (dds.pixelFormat.flags == DDS_RGB || dds.pixelFormat.flags == DDS_RGBA) {
		//immutable bitcount = getUInt(88);
		if (dds.pixelFormat.rgbBitCount == 24) pf = DDSPixelFormat.RGB888;
		else if (dds.pixelFormat.rgbBitCount == 32) pf = DDSPixelFormat.ARGB8888;
		else throw new DDSLoadException("Unknown format");
	}
}


// extracts colors from a dds color block
private void DDSGetColorBlockColors (ref const(ddsColorBlock_t) block, RGBA32[] colors) @safe {
	ushort word;

	// color 0
	word = block.colors[0];
	colors[0].alpha = 0xff;

	// extract rgb bits
	colors[0].blue = cast(ubyte)word;
	colors[0].blue <<= 3;
	colors[0].blue |= (colors[0].blue>>5);
	word >>= 5;
	colors[0].green = cast(ubyte)word;
	colors[0].green <<= 2;
	colors[0].green |= (colors[0].green>>5);
	word >>= 6;
	colors[0].red = cast(ubyte)word;
	colors[0].red <<= 3;
	colors[0].red |= (colors[0].red>>5);

	// same for color 1
	word = block.colors[1];
	colors[1].alpha = 0xff;

	// extract rgb bits
	colors[1].blue = cast(ubyte)word;
	colors[1].blue <<= 3;
	colors[1].blue |= (colors[1].blue>>5);
	word >>= 5;
	colors[1].green = cast(ubyte)word;
	colors[1].green <<= 2;
	colors[1].green |= (colors[1].green>>5);
	word >>= 6;
	colors[1].red = cast(ubyte)word;
	colors[1].red <<= 3;
	colors[1].red |= (colors[1].red>>5);

	// use this for all but the super-freak math method
	if (block.colors[0] > block.colors[1]) {
		/* four-color block: derive the other two colors.
			 00 = color 0, 01 = color 1, 10 = color 2, 11 = color 3
			 these two bit codes correspond to the 2-bit fields
			 stored in the 64-bit block. */
		word = (cast(ushort)colors[0].red*2+cast(ushort)colors[1].red)/3;
		// no +1 for rounding
		// as bits have been shifted to 888
		colors[2].red = cast(ubyte) word;
		word = (cast(ushort)colors[0].green*2+cast(ushort)colors[1].green)/3;
		colors[2].green = cast(ubyte) word;
		word = (cast(ushort)colors[0].blue*2+cast(ushort)colors[1].blue)/3;
		colors[2].blue = cast(ubyte)word;
		colors[2].alpha = 0xff;

		word = (cast(ushort)colors[0].red+cast(ushort)colors[1].red*2)/3;
		colors[3].red = cast(ubyte)word;
		word = (cast(ushort)colors[0].green+cast(ushort)colors[1].green*2)/3;
		colors[3].green = cast(ubyte)word;
		word = (cast(ushort)colors[0].blue+cast(ushort)colors[1].blue*2)/3;
		colors[3].blue = cast(ubyte)word;
		colors[3].alpha = 0xff;
	} else {
		/* three-color block: derive the other color.
			 00 = color 0, 01 = color 1, 10 = color 2,
			 11 = transparent.
			 These two bit codes correspond to the 2-bit fields
			 stored in the 64-bit block */
		word = (cast(ushort)colors[0].red+cast(ushort)colors[1].red)/2;
		colors[2].red = cast(ubyte)word;
		word = (cast(ushort)colors[0].green+cast(ushort)colors[1].green)/2;
		colors[2].green = cast(ubyte)word;
		word = (cast(ushort)colors[0].blue+cast(ushort)colors[1].blue)/2;
		colors[2].blue = cast(ubyte)word;
		colors[2].alpha = 0xff;

		// random color to indicate alpha
		colors[3].red = 0x00;
		colors[3].green = 0xff;
		colors[3].blue = 0xff;
		colors[3].alpha = 0x00;
	}
}


//decodes a dds color block
//FIXME: make endian-safe
private void DDSDecodeColorBlock (RGBA32[] pixel, const(ddsColorBlock_t)* block, int width, const(RGBA32)[] colors) @safe {
	uint bits;
	static immutable uint[4] masks = [ 3, 12, 3<<4, 3<<6 ]; // bit masks = 00000011, 00001100, 00110000, 11000000
	static immutable ubyte[4] shift = [ 0, 2, 4, 6 ];
	// r steps through lines in y
	// no width * 4 as unsigned int ptr inc will * 4
	for (int r = 0; r < 4; ++r, pixel = pixel[width-4 .. $]) {
		// width * 4 bytes per pixel per line, each j dxtc row is 4 lines of pixels
		// n steps through pixels
		for (int n = 0; n < 4; ++n) {
			bits = block.row[r] & masks[n];
			bits >>= shift[n];
			switch (bits) {
				case 0: pixel[0] = colors[0]; break;
				case 1: pixel[0] = colors[1]; break;
				case 2: pixel[0] = colors[2]; break;
				case 3: pixel[0] = colors[3]; break;
				default: break; // invalid
			}
			pixel = pixel[1 .. $];
		}
		if (pixel.length < width - 4) {
			break;
		}
	}
}


// decodes a dds explicit alpha block
//FIXME: endianness
private void DDSDecodeAlphaExplicit (RGBA32[] pixel, const(ddsAlphaBlockExplicit_t)* alphaBlock, int width) @safe {
	int row, pix;
	ushort word;
	RGBA32 color;

	// clear color
	color.red = 0;
	color.green = 0;
	color.blue = 0;

	// walk rows
	for (row = 0; row < 4; ++row, pixel = pixel[width-4 .. $]) {
		word = alphaBlock.row[row];
		// walk pixels
		for (pix = 0; pix < 4; ++pix) {
			// zero the alpha bits of image pixel
			color.alpha = word & 0x000F;
			color.alpha = cast(ubyte)(color.alpha | (color.alpha << 4));
			pixel[0].alpha = color.alpha;
			word >>= 4; // move next bits to lowest 4
			pixel = pixel[1 .. $]; // move to next pixel in the row
		}
		if (pixel.length < width - 4) {
			break;
		}
	}
}


// decodes interpolated alpha block
private void DDSDecodeAlpha3BitLinear (RGBA32[] pixel, const(ddsAlphaBlock3BitLinear_t)* alphaBlock, int width) @safe {
	int row, pix;
	uint stuff;
	ubyte[4][4] bits;
	ushort[8] alphas;
	RGBA32[4][4] aColors;

	// get initial alphas
	alphas[0] = alphaBlock.alpha0;
	alphas[1] = alphaBlock.alpha1;

	if (alphas[0] > alphas[1]) {
		// 8-alpha block
		// 000 = alpha_0, 001 = alpha_1, others are interpolated
		alphas[2] = (6*alphas[0]+alphas[1])/7; // bit code 010
		alphas[3] = (5*alphas[0]+2*alphas[1])/7; // bit code 011
		alphas[4] = (4*alphas[0]+3*alphas[1])/7; // bit code 100
		alphas[5] = (3*alphas[0]+4*alphas[1])/7; // bit code 101
		alphas[6] = (2*alphas[0]+5*alphas[1])/7; // bit code 110
		alphas[7] = (alphas[0]+6*alphas[1])/7; // bit code 111
	} else {
		// 6-alpha block
		// 000 = alpha_0, 001 = alpha_1, others are interpolated
		alphas[2] = (4*alphas[0]+alphas[1])/5; // bit code 010
		alphas[3] = (3*alphas[0]+2*alphas[1])/5; // bit code 011
		alphas[4] = (2*alphas[0]+3*alphas[1])/5; // bit code 100
		alphas[5] = (alphas[0]+4*alphas[1])/5; // bit code 101
		alphas[6] = 0; // bit code 110
		alphas[7] = 255; // bit code 111
	}

	// decode 3-bit fields into array of 16 bytes with same value

	// first two rows of 4 pixels each
	stuff = alphaBlock.stuff[0] | (alphaBlock.stuff[1] << 8) | (alphaBlock.stuff[2] << 16);

	bits[0][0] = stuff & 7;
	stuff >>= 3;
	bits[0][1] = stuff & 7;
	stuff >>= 3;
	bits[0][2] = stuff & 7;
	stuff >>= 3;
	bits[0][3] = stuff & 7;
	stuff >>= 3;
	bits[1][0] = stuff & 7;
	stuff >>= 3;
	bits[1][1] = stuff & 7;
	stuff >>= 3;
	bits[1][2] = stuff & 7;
	stuff >>= 3;
	bits[1][3] = stuff & 7;

	// last two rows
	stuff = alphaBlock.stuff[3] | (alphaBlock.stuff[4] << 8) | (alphaBlock.stuff[5] << 16); // last 3 bytes

	bits[2][0] = stuff & 7;
	stuff >>= 3;
	bits[2][1] = stuff & 7;
	stuff >>= 3;
	bits[2][2] = stuff & 7;
	stuff >>= 3;
	bits[2][3] = stuff & 7;
	stuff >>= 3;
	bits[3][0] = stuff & 7;
	stuff >>= 3;
	bits[3][1] = stuff & 7;
	stuff >>= 3;
	bits[3][2] = stuff & 7;
	stuff >>= 3;
	bits[3][3] = stuff & 7;

	// decode the codes into alpha values
	for (row = 0; row < 4; ++row) {
		for (pix = 0; pix < 4; ++pix) {
			aColors[row][pix].red = 0;
			aColors[row][pix].green = 0;
			aColors[row][pix].blue = 0;
			aColors[row][pix].alpha = cast(ubyte)alphas[bits[row][pix]];
		}
	}

	// write out alpha values to the image bits
	for (row = 0; row < 4; ++row, pixel = pixel[width-4 .. $]) {
		for (pix = 0; pix < 4; ++pix) {
			// zero the alpha bits of image pixel
			// or the bits into the prev. nulled alpha
			pixel[0].alpha = aColors[row][pix].alpha;
			pixel = pixel[1 .. $];
		}
		if (pixel.length < width - 4) {
			break;
		}
	}
}


// decompresses a dxt1 format texture
private void DDSDecompressDXT1 (ref const(ddsBuffer_t) dds, const(ubyte)[] fileData, int width, int height, RGBA32[] pixels) @safe {
	RGBA32[4] colors;
	immutable int xBlocks = width / 4;
	immutable int yBlocks = height / 4;
	// 8 bytes per block
	auto block = cast(const(DDSBlock)[])fileData;
	foreach (immutable y; 0..yBlocks) {
		foreach (immutable x; 0..xBlocks) {
			DDSGetColorBlockColors(block[0].colorBlock, colors);
			auto pixel = pixels[x*4+(y*4)*width .. $];
			DDSDecodeColorBlock(pixel, &block[0].colorBlock, width, colors);
			block = block[1 .. $];
		}
	}
}


// decompresses a dxt3 format texture
private void DDSDecompressDXT3 (ref const(ddsBuffer_t) dds, const(ubyte)[] fileData, int width, int height, RGBA32[] pixels) @safe {
	RGBA32[4] colors;

	// setup
	immutable int xBlocks = width / 4;
	immutable int yBlocks = height / 4;

	// create zero alpha
	colors[0] = RGBA32(red: 255, green: 255, blue: 255, alpha: 0);

	// 8 bytes per block, 1 block for alpha, 1 block for color
	auto block = cast(const(DDSBlock)[])fileData;
	foreach (immutable y; 0..yBlocks) {
		foreach (immutable x; 0..xBlocks) {
			// get color block
			DDSGetColorBlockColors(block[1].colorBlock, colors);
			// decode color block
			auto pixel = pixels[x*4+(y*4)*width .. $];
			DDSDecodeColorBlock(pixel, &block[1].colorBlock, width, colors);
			// overwrite alpha bits with alpha block
			DDSDecodeAlphaExplicit(pixel, &block[0].alphaBlockExplicit, width);
			block = block[2 .. $];
		}
	}
}


// decompresses a dxt5 format texture
private void DDSDecompressDXT5 (ref const(ddsBuffer_t) dds, const(ubyte)[] fileData, int width, int height, RGBA32[] pixels) @safe {
	RGBA32[4] colors;

	// setup
	immutable int xBlocks = width / 4;
	immutable int yBlocks = height / 4;

	// create zero alpha
	colors[0] = RGBA32(red: 255, green: 255, blue: 255, alpha: 0);

	// 8 bytes per block, 1 block for alpha, 1 block for color
	auto block = cast(const(DDSBlock)[])fileData;
	foreach (immutable y; 0..yBlocks) {
		foreach (immutable x; 0..xBlocks) {
			// get color block
			DDSGetColorBlockColors(block[1].colorBlock, colors);
			// decode color block
			auto pixel = pixels[x*4+(y*4)*width .. $];
			DDSDecodeColorBlock(pixel, &block[1].colorBlock, width, colors);
			// overwrite alpha bits with alpha block
			DDSDecodeAlpha3BitLinear(pixel, &block[0].alphaBlock3BitLinear, width);
			block = block[2 .. $];
		}
	}
}


private void unmultiply(scope RGBA32[] pixels) @safe {
	// premultiplied alpha
	foreach (ref RGBA32 clr; pixels) {
		if (clr.alpha != 0) {
			clr.red = cast(ubyte)min(255, clr.red*255/clr.alpha);
			clr.green = cast(ubyte)min(255, clr.green*255/clr.alpha);
			clr.blue = cast(ubyte)min(255, clr.blue*255/clr.alpha);
		}
	}
}


// decompresses a dxt2 format texture (FIXME: un-premultiply alpha)
private void DDSDecompressDXT2 (ref const(ddsBuffer_t) dds, const(ubyte)[] fileData, int width, int height, RGBA32[] pixels) @safe {
	// decompress dxt3 first
	DDSDecompressDXT3(dds, fileData, width, height, pixels);
	//FIXME: is un-premultiply correct?
	unmultiply(pixels);
}


// decompresses a dxt4 format texture (FIXME: un-premultiply alpha)
private void DDSDecompressDXT4 (ref const(ddsBuffer_t) dds, const(ubyte)[] fileData, int width, int height, RGBA32[] pixels) @safe {
	// decompress dxt5 first
	DDSDecompressDXT5(dds, fileData, width, height, pixels);
	//FIXME: is un-premultiply correct?
	unmultiply(pixels);
}


// decompresses an argb 8888 format texture
private void DDSDecompressARGB8888 (ref const(ddsBuffer_t) dds, const(ubyte)[] fileData, int width, int height, RGBA32[] pixels) @safe {
	foreach (idx, src; (cast(const(BGRA32)[])fileData)[0 .. width * height]) {
		pixels[idx] = src.convert!RGBA32;
	}
}


// decompresses an rgb 888 format texture
private void DDSDecompressRGB888 (ref const(ddsBuffer_t) dds, const(ubyte)[] fileData, int width, int height, RGBA32[] pixels) @safe {
	foreach (idx, src; (cast(const(BGR24)[])fileData)[0 .. width * height]) {
		pixels[idx] = src.convert!RGBA32;
	}
}
