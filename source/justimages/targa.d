//ketmar: Adam didn't wrote this, don't blame him!
module justimages.targa;

import justimages.color;
import tilemagic.colours;
import std.algorithm.comparison : min;
import std.stdio : File; // sorry


// ////////////////////////////////////////////////////////////////////////// //
public MemoryImage loadTgaMem (const(void)[] buf, const(char)[] filename=null) {
  static struct MemRO {
    const(ubyte)[] data;
    long pos;

    this (const(void)[] abuf) { data = cast(const(ubyte)[])abuf; }

    long tell () @safe { return pos; }
    long size () @safe { return data.length; }

    void seek (long offset, int whence=Seek.Set) @safe {
      switch (whence) {
        case Seek.Set:
          if (offset < 0 || offset > data.length) throw new Exception("invalid offset");
          pos = offset;
          break;
        case Seek.Cur:
          if (offset < -pos || offset > data.length-pos) throw new Exception("invalid offset");
          pos += offset;
          break;
        case Seek.End:
          pos = data.length+offset;
          if (pos < 0 || pos > data.length) throw new Exception("invalid offset");
          break;
        default:
          throw new Exception("invalid offset origin");
      }
    }

    ptrdiff_t read (ubyte[] buf) @safe {
      if (pos >= data.length) return 0;
      if (buf.length > 0) {
        long rlen = data.length-pos;
        if (rlen >= buf.length) rlen = buf.length;
        assert(rlen != 0);
        buf[0 .. rlen] = data[pos .. pos + rlen];
        pos += rlen;
        return cast(ptrdiff_t)rlen;
      } else {
        return 0;
      }
    }
  }

  auto rd = MemRO(buf);
  return loadTga(rd, filename);
}

public MemoryImage loadTga (File fl) { return loadTgaImpl(fl, fl.name); }
public MemoryImage loadTga(const(char)[] fname) {
  static if (is(T == typeof(null))) {
    throw new Exception("cannot load nameless tga");
  } else {
    static if (is(T == string)) {
      return loadTga(File(fname), fname);
    } else {
      return loadTga(File(fname.idup), fname);
    }
  }
}
/*@safe*/ unittest {
  {
    const tga = loadTga("samples/test.tga");
    assert(tga[0, 0] == RGBA32(0, 0, 255, 255));
    assert(tga[128, 0] == RGBA32(0, 255, 0, 255));
    assert(tga[0, 128] == RGBA32(255, 0, 0, 255));
    assert(tga[128, 128] == RGBA32(0, 0, 0, 0));
  }
}

// pass filename to ease detection
// hack around "has scoped destruction, cannot build closure"
public MemoryImage loadTga(ST) (auto ref ST fl, const(char)[] filename=null) if (isReadableStream!ST && isSeekableStream!ST) { return loadTgaImpl(fl, filename); }

static struct TGAHeader {
  align(1):
  ubyte idsize;
  ubyte cmapType;
  ubyte imgType;
  ushort cmapFirstIdx;
  ushort cmapSize;
  ubyte cmapElementSize;
  ushort originX;
  ushort originY;
  ushort width;
  ushort height;
  ubyte bpp;
  ubyte imgdsc;

  bool zeroBits () const pure nothrow @safe @nogc { return ((imgdsc&0xc0) == 0); }
  bool xflip () const pure nothrow @safe @nogc { return ((imgdsc&0b010000) != 0); }
  bool yflip () const pure nothrow @safe @nogc { return ((imgdsc&0b100000) == 0); }
}
private MemoryImage loadTgaImpl(ST) (auto ref ST fl, const(char)[] filename) {
  enum TGAFILESIGNATURE = "TRUEVISION-XFILE.\x00";

  static immutable ubyte[32] cmap16 = [0,8,16,25,33,41,49,58,66,74,82,90,99,107,115,123,132,140,148,156,165,173,181,189,197,206,214,222,230,239,247,255];


  static struct ExtFooter {
    uint extofs;
    uint devdirofs;
    char[18] sign=0;
  }

  static struct Extension {
    ushort size;
    char[41] author=0;
    char[324] comments=0;
    ushort month, day, year;
    ushort hour, minute, second;
    char[41] jid=0;
    ushort jhours, jmins, jsecs;
    char[41] producer=0;
    ushort prodVer;
    ubyte prodSubVer;
    ubyte keyR, keyG, keyB, keyZero;
    ushort pixratioN, pixratioD;
    ushort gammaN, gammaD;
    uint ccofs;
    uint wtfofs;
    uint scanlineofs;
    ubyte attrType;
  }

  ExtFooter extfooter;
  uint rleBC, rleDC;
  ubyte[4] rleLast;
  RGBA32[256] cmap;

  void readPixel(bool asRLE, uint bytesPerPixel) (ubyte[] pixel, scope ubyte delegate () readByte) {
    static if (asRLE) {
      if (rleDC > 0) {
        // still counting
        static if (bytesPerPixel == 1) pixel.ptr[0] = rleLast.ptr[0];
        else pixel.ptr[0..bytesPerPixel] = rleLast.ptr[0..bytesPerPixel];
        --rleDC;
        return;
      }
      if (rleBC > 0) {
        --rleBC;
      } else {
        ubyte b = readByte();
        if (b&0x80) rleDC = (b&0x7f); else rleBC = (b&0x7f);
      }
      foreach (immutable idx; 0..bytesPerPixel) rleLast.ptr[idx] = pixel.ptr[idx] = readByte();
    } else {
      foreach (immutable idx; 0..bytesPerPixel) pixel.ptr[idx] = readByte();
    }
  }

  // 8 bit color-mapped row
  RGBA32 readColorCM8(bool asRLE) (scope ubyte delegate () readByte) {
    ubyte[1] pixel = void;
    readPixel!(asRLE, 1)(pixel[], readByte);
    auto cmp = cast(const(ubyte)*)(cmap.ptr+pixel.ptr[0]);
    return RGBA32(cmp[0], cmp[1], cmp[2]);
  }

  // 8 bit greyscale
  RGBA32 readColorBM8(bool asRLE) (scope ubyte delegate () readByte) {
    ubyte[1] pixel = void;
    readPixel!(asRLE, 1)(pixel[], readByte);
    return RGBA32(pixel.ptr[0], pixel.ptr[0], pixel.ptr[0]);
  }

  // 16 bit greyscale
  RGBA32 readColorBM16(bool asRLE) (scope ubyte delegate () readByte) {
    ubyte[2] pixel = void;
    readPixel!(asRLE, 2)(pixel[], readByte);
    immutable ubyte v = cast(ubyte)((pixel.ptr[0]|(pixel.ptr[1]<<8))>>8);
    return RGBA32(v, v, v);
  }

  // 16 bit
  RGBA32 readColor16(bool asRLE) (scope ubyte delegate () readByte) {
    ubyte[2] pixel = void;
    readPixel!(asRLE, 2)(pixel[], readByte);
    immutable v = pixel.ptr[0]+(pixel.ptr[1]<<8);
    return RGBA32(cmap16.ptr[(v>>10)&0x1f], cmap16.ptr[(v>>5)&0x1f], cmap16.ptr[v&0x1f]);
  }

  // 24 bit or 32 bit
  RGBA32 readColorTrue(bool asRLE, uint bytesPerPixel) (scope ubyte delegate () readByte) {
    ubyte[bytesPerPixel] pixel = void;
    readPixel!(asRLE, bytesPerPixel)(pixel[], readByte);
    static if (bytesPerPixel == 4) {
      return RGBA32(pixel.ptr[2], pixel.ptr[1], pixel.ptr[0], pixel.ptr[3]);
    } else {
      return RGBA32(pixel.ptr[2], pixel.ptr[1], pixel.ptr[0]);
    }
  }

  bool isGoodExtension (const(char)[] filename) {
    if (filename.length >= 4) {
      // try extension
      auto ext = filename[$-4..$];
      if (ext[0] == '.' && (ext[1] == 'T' || ext[1] == 't') && (ext[2] == 'G' || ext[2] == 'g') && (ext[3] == 'A' || ext[3] == 'a')) return true;
    }
    // try signature
    return false;
  }

  bool detect(ST) (auto ref ST fl, const(char)[] filename) if (isReadableStream!ST && isSeekableStream!ST) {
    bool goodext = false;
    if (fl.size < 45) return false; // minimal 1x1 tga
    if (filename.length) { goodext = isGoodExtension(filename); if (!goodext) return false; }
    // try footer
    fl.seek(-(4*2+18), Seek.End);
    extfooter.extofs = fl.readNum!uint;
    extfooter.devdirofs = fl.readNum!uint;
    fl.rawReadExact(extfooter.sign[]);
    if (extfooter.sign != TGAFILESIGNATURE) {
      //if (!goodext) return false;
      extfooter = extfooter.init;
      return true; // alas, footer is optional
    }
    return true;
  }

  if (!detect(fl, filename)) throw new Exception("not a TGA");
  fl.seek(0);
  TGAHeader hdr;
  fl.readStruct(hdr);
  // parse header
  // arbitrary size limits
  if (hdr.width  == 0 || hdr.width > 32000) throw new Exception("invalid tga width");
  if (hdr.height == 0 || hdr.height > 32000) throw new Exception("invalid tga height");
  switch (hdr.bpp) {
    case 1: case 2: case 4: case 8: case 15: case 16: case 24: case 32: break;
    default: throw new Exception("invalid tga bpp");
  }
  uint bytesPerPixel = ((hdr.bpp)>>3);
  if (bytesPerPixel == 0 || bytesPerPixel > 4) throw new Exception("invalid tga pixel size");
  bool loadCM = false;
  // get the row reading function
  ubyte readByte () { ubyte b; fl.rawReadExact((&b)[0..1]); return b; }
  scope RGBA32 delegate (scope ubyte delegate () readByte) readColor;
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
      auto cmp = cmap.ptr;
      switch (colorEntryBytes) {
        case 2:
          foreach (immutable n; 0..hdr.cmapSize) {
            uint v = readCMB();
            v |= readCMB()<<8;
            cmp.blue = cmap16.ptr[v&0x1f];
            cmp.green = cmap16.ptr[(v>>5)&0x1f];
            cmp.red = cmap16.ptr[(v>>10)&0x1f];
            ++cmp;
          }
          break;
        case 3:
          foreach (immutable n; 0..hdr.cmapSize) {
            cmp.blue = readCMB();
            cmp.green = readCMB();
            cmp.red = readCMB();
            ++cmp;
          }
          break;
        case 4:
          foreach (immutable n; 0..hdr.cmapSize) {
            cmp.blue = readCMB();
            cmp.green = readCMB();
            cmp.red = readCMB();
            cmp.alpha = readCMB();
            ++cmp;
          }
          break;
        default: throw new Exception("invalid tga colormap type");
      }
    } else {
      // skip colormap
      fl.seek(colorMapBytes, Seek.Cur);
    }
  }

  // now load the data
  fl.seek(hdr.idsize, Seek.Cur);
  if (hdr.cmapType != 0) loadColormap();

  // we don't know if alpha is premultiplied yet
  bool hasAlpha = (bytesPerPixel == 4);
  bool validAlpha = hasAlpha;
  bool premult = false;

  auto tcimg = new TrueColorImage(hdr.width, hdr.height);
  scope(failure) .destroy(tcimg);

  {
    // read image data
    immutable bool xflip = hdr.xflip, yflip = hdr.yflip;
    RGBA32* pixdata = tcimg.colours[].ptr;
    if (yflip) pixdata += (hdr.height-1)*hdr.width;
    foreach (immutable y; 0..hdr.height) {
      auto d = pixdata;
      if (xflip) d += hdr.width-1;
      foreach (immutable x; 0..hdr.width) {
        *d = readColor(&readByte);
        if (xflip) --d; else ++d;
      }
      if (yflip) pixdata -= hdr.width; else pixdata += hdr.width;
    }
  }

  if (hasAlpha) {
    if (extfooter.extofs != 0) {
      Extension ext;
      fl.seek(extfooter.extofs);
      fl.readStruct(ext);
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
      foreach (ref RGBA32 clr; tcimg.colours) if (clr.alpha != 0) { validAlpha = true; break; }
    }
    if (!validAlpha) foreach (ref RGBA32 clr; tcimg.colours) clr.alpha = 255;
  }
  return tcimg;
}


// ////////////////////////////////////////////////////////////////////////// //
private:
import core.stdc.stdio : SEEK_SET, SEEK_CUR, SEEK_END;

enum Seek : int {
  Set = SEEK_SET,
  Cur = SEEK_CUR,
  End = SEEK_END,
}


// ////////////////////////////////////////////////////////////////////////// //
// augmentation checks
// is this "low-level" stream that can be read?
enum isLowLevelStreamR(T) = is(typeof((inout int=0) {
  auto t = T.init;
  ubyte[1] b;
  ptrdiff_t r = t.read(b[]);
}));

// is this "low-level" stream that can be written?
enum isLowLevelStreamW(T) = is(typeof((inout int=0) {
  auto t = T.init;
  ubyte[1] b;
  ptrdiff_t w = t.write(b.ptr, 1);
}));


// is this "low-level" stream that can be seeked?
enum isLowLevelStreamS(T) = is(typeof((inout int=0) {
  auto t = T.init;
  long p = t.lseek(0, 0);
}));


// ////////////////////////////////////////////////////////////////////////// //
// augment low-level streams with `rawRead`
T[] rawRead(ST, T) (auto ref ST st, T[] buf) if (isLowLevelStreamR!ST && !is(T == const) && !is(T == immutable)) {
  if (buf.length > 0) {
    auto res = st.read(cast(ubyte[])buf);
    if (res == -1 || res%T.sizeof != 0) throw new Exception("read error");
    return buf[0..res/T.sizeof];
  } else {
    return buf[0..0];
  }
}

// augment low-level streams with `rawWrite`
void rawWrite(ST, T) (auto ref ST st, in T[] buf) if (isLowLevelStreamW!ST) {
  if (buf.length > 0) {
    auto res = st.write(buf.ptr, buf.length*T.sizeof);
    if (res == -1 || res%T.sizeof != 0) throw new Exception("write error");
  }
}

// read exact size or throw error
package(justimages) T[] rawReadExact(ST, T) (auto ref ST st, T[] buf) if (isReadableStream!ST && !is(T == const) && !is(T == immutable)) {
  if (buf.length == 0) return buf;
  auto left = buf.length*T.sizeof;
  auto dp = cast(ubyte*)buf.ptr;
  while (left > 0) {
    auto res = st.rawRead(cast(void[])(dp[0..left]));
    if (res.length == 0) throw new Exception("read error");
    dp += res.length;
    left -= res.length;
  }
  return buf;
}

// write exact size or throw error (just for convenience)
void rawWriteExact(ST, T) (auto ref ST st, in T[] buf) if (isWriteableStream!ST) { st.rawWrite(buf); }

// if stream doesn't have `.size`, but can be seeked, emulate it
long size(ST) (auto ref ST st) if (isSeekableStream!ST && !streamHasSize!ST) {
  auto opos = st.tell;
  st.seek(0, Seek.End);
  auto res = st.tell;
  st.seek(opos);
  return res;
}


// ////////////////////////////////////////////////////////////////////////// //
// check if a given stream supports `eof`
enum streamHasEof(T) = is(typeof((inout int=0) {
  auto t = T.init;
  bool n = t.eof;
}));

// check if a given stream supports `seek`
enum streamHasSeek(T) = is(typeof((inout int=0) {
  import core.stdc.stdio : SEEK_END;
  auto t = T.init;
  t.seek(0);
  t.seek(0, SEEK_END);
}));

// check if a given stream supports `tell`
enum streamHasTell(T) = is(typeof((inout int=0) {
  auto t = T.init;
  long pos = t.tell;
}));

// check if a given stream supports `size`
enum streamHasSize(T) = is(typeof((inout int=0) {
  auto t = T.init;
  long pos = t.size;
}));

// check if a given stream supports `rawRead()`.
// it's enough to support `void[] rawRead (void[] buf)`
enum isReadableStream(T) = is(typeof((inout int=0) {
  auto t = T.init;
  ubyte[1] b;
  t.rawRead(b[]);
}));

// check if a given stream supports `rawWrite()`.
// it's enough to support `inout(void)[] rawWrite (inout(void)[] buf)`
enum isWriteableStream(T) = is(typeof((inout int=0) {
  auto t = T.init;
  ubyte[1] b;
  t.rawWrite(cast(void[])b);
}));

// check if a given stream supports `.seek(ofs, [whence])`, and `.tell`
enum isSeekableStream(T) = (streamHasSeek!T && streamHasTell!T);

// check if we can get size of a given stream.
// this can be done either with `.size`, or with `.seek` and `.tell`
enum isSizedStream(T) = (streamHasSize!T || isSeekableStream!T);

// ////////////////////////////////////////////////////////////////////////// //
private enum isGoodEndianness(string s) = (s == "LE" || s == "le" || s == "BE" || s == "be");

private template isLittleEndianness(string s) if (isGoodEndianness!s) {
  enum isLittleEndianness = (s == "LE" || s == "le");
}

private template isBigEndianness(string s) if (isGoodEndianness!s) {
  enum isLittleEndianness = (s == "BE" || s == "be");
}

private template isSystemEndianness(string s) if (isGoodEndianness!s) {
  version(LittleEndian) {
    enum isSystemEndianness = isLittleEndianness!s;
  } else {
    enum isSystemEndianness = isBigEndianness!s;
  }
}


// ////////////////////////////////////////////////////////////////////////// //
// write integer value of the given type, with the given endianness (default: little-endian)
// usage: st.writeNum!ubyte(10)
void writeNum(T, string es="LE", ST) (auto ref ST st, T n) if (isGoodEndianness!es && isWriteableStream!ST && __traits(isIntegral, T)) {
  static assert(T.sizeof <= 8); // just in case
  static if (isSystemEndianness!es) {
    st.rawWriteExact((&n)[0..1]);
  } else {
    ubyte[T.sizeof] b = void;
    version(LittleEndian) {
      // convert to big-endian
      foreach_reverse (ref x; b) { x = n&0xff; n >>= 8; }
    } else {
      // convert to little-endian
      foreach (ref x; b) { x = n&0xff; n >>= 8; }
    }
    st.rawWriteExact(b[]);
  }
}


// read integer value of the given type, with the given endianness (default: little-endian)
// usage: auto v = st.readNum!ubyte
T readNum(T, string es="LE", ST) (auto ref ST st) if (isGoodEndianness!es && isReadableStream!ST && __traits(isIntegral, T)) {
  static assert(T.sizeof <= 8); // just in case
  static if (isSystemEndianness!es) {
    T v = void;
    st.rawReadExact((&v)[0..1]);
    return v;
  } else {
    ubyte[T.sizeof] b = void;
    st.rawReadExact(b[]);
    T v = 0;
    version(LittleEndian) {
      // convert from big-endian
      foreach (ubyte x; b) { v <<= 8; v |= x; }
    } else {
      // conver from little-endian
      foreach_reverse (ubyte x; b) { v <<= 8; v |= x; }
    }
    return v;
  }
}


private enum reverseBytesMixin = "
  foreach (idx; 0..b.length/2) {
    ubyte t = b[idx];
    b[idx] = b[$-idx-1];
    b[$-idx-1] = t;
  }
";


// write floating value of the given type, with the given endianness (default: little-endian)
// usage: st.writeNum!float(10)
void writeNum(T, string es="LE", ST) (auto ref ST st, T n) if (isGoodEndianness!es && isWriteableStream!ST && __traits(isFloating, T)) {
  static assert(T.sizeof <= 8);
  static if (isSystemEndianness!es) {
    st.rawWriteExact((&n)[0..1]);
  } else {
    import core.stdc.string : memcpy;
    ubyte[T.sizeof] b = void;
    memcpy(b.ptr, &v, T.sizeof);
    mixin(reverseBytesMixin);
    st.rawWriteExact(b[]);
  }
}


// read floating value of the given type, with the given endianness (default: little-endian)
// usage: auto v = st.readNum!float
T readNum(T, string es="LE", ST) (auto ref ST st) if (isGoodEndianness!es && isReadableStream!ST && __traits(isFloating, T)) {
  static assert(T.sizeof <= 8);
  T v = void;
  static if (isSystemEndianness!es) {
    st.rawReadExact((&v)[0..1]);
  } else {
    import core.stdc.string : memcpy;
    ubyte[T.sizeof] b = void;
    st.rawReadExact(b[]);
    mixin(reverseBytesMixin);
    memcpy(&v, b.ptr, T.sizeof);
  }
  return v;
}


// ////////////////////////////////////////////////////////////////////////// //
void readStruct(string es="LE", SS, ST) (auto ref ST fl, ref SS st)
if (is(SS == struct) && isGoodEndianness!es && isReadableStream!ST)
{
  void unserData(T) (ref T v) {
    import std.traits : Unqual;
    alias UT = Unqual!T;
    static if (is(T : V[], V)) {
      // array
      static if (__traits(isStaticArray, T)) {
        foreach (ref it; v) unserData(it);
      } else static if (is(UT == char)) {
        // special case: dynamic `char[]` array will be loaded as asciiz string
        char c;
        for (;;) {
          if (fl.rawRead((&c)[0..1]).length == 0) break; // don't require trailing zero on eof
          if (c == 0) break;
          v ~= c;
        }
      } else {
        assert(0, "cannot load dynamic arrays yet");
      }
    } else static if (is(T : V[K], K, V)) {
      assert(0, "cannot load associative arrays yet");
    } else static if (__traits(isIntegral, UT) || __traits(isFloating, UT)) {
      // this takes care of `*char` and `bool` too
      v = cast(UT)fl.readNum!(UT, es);
    } else static if (is(T == struct)) {
      // struct
      import std.traits : FieldNameTuple, hasUDA;
      foreach (string fldname; FieldNameTuple!T) {
        unserData(__traits(getMember, v, fldname));
      }
    }
  }

  unserData(st);
}
