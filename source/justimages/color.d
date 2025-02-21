/++
	Base module for working with colors and in-memory image pixmaps.

	Also has various basic data type definitions that are generally
	useful with images like [Point], [Size], and [Rectangle].
+/
module justimages.color;

import tilemagic.colours.formats;

@safe:

import std.algorithm.comparison;
import std.algorithm.iteration;
import std.algorithm.searching;
import std.algorithm.sorting;
import std.conv;
import std.math;
import std.range;

/**
	This provides two image classes and a bunch of functions that work on them.

	Why are they separate classes? I think the operations on the two of them
	are necessarily different. There's a whole bunch of operations that only
	really work on truecolor (blurs, gradients), and a few that only work
	on indexed images (palette swaps).

	Even putpixel is pretty different. On indexed, it is a palette entry's
	index number. On truecolor, it is the actual color.

	A greyscale image is the weird thing in the middle. It is truecolor, but
	fits in the same size as indexed. Still, I'd say it is a specialization
	of truecolor.

	There is a subset that works on both

*/

/// An image in memory
interface MemoryImage {
	//IndexedImage convertToIndexedImage() const;
	//TrueColorImage convertToTrueColor() const;

	/// gets it as a TrueColorImage. May return this or may do a conversion and return a new image
	TrueColorImage getAsTrueColorImage() pure nothrow @safe;

	/// Image width, in pixels
	int width() const pure nothrow @safe @nogc;

	/// Image height, in pixels
	int height() const pure nothrow @safe @nogc;

	/// Get image pixel. Slow, but returns valid RGBA color (completely transparent for off-image pixels).
	deprecated final RGBA32 getPixel(int x, int y) const pure @safe {
		return this[x, y];
	}

  /// Set image pixel.
	deprecated final void setPixel(int x, int y, in RGBA32 clr) @safe {
		this[x, y] = clr;
	}
	RGBA32 opIndex(size_t x, size_t y) const @safe pure;

	void opIndexAssign(in RGBA32 clr, size_t x, size_t y) @safe pure;

	/// Returns a copy of the image
	MemoryImage clone() const pure nothrow @safe;

	/// Load image from file. This will import justimages.image to do the actual work, and cost nothing if you don't use it.
	static MemoryImage fromImage(const(char)[] filename) @system {
		// yay, we have image loader here, try it!
		import justimages.image;
		return loadImageFromFile(filename);
	}

	// ***This method is deliberately not publicly documented.***
	// What it does is unconditionally frees internal image storage, without any sanity checks.
	// If you will do this, make sure that you have no references to image data left (like
	// slices of [data] array, for example). Those references will become invalid, and WILL
	// lead to Undefined Behavior.
	// tl;dr: IF YOU HAVE *ANY* QUESTIONS REGARDING THIS COMMENT, DON'T USE THIS!
	// Note to implementors: it is safe to simply do nothing in this method.
	// Also, it should be safe to call this method twice or more.
	void clearInternal () nothrow @safe;

	/// Convenient alias for `fromImage`
	alias fromImageFile = fromImage;
}

/// An image that consists of indexes into a color palette. Use [getAsTrueColorImage]() if you don't care about palettes
class IndexedImage : MemoryImage {
	bool hasAlpha;

	/// .
	RGBA32[] palette;
	/// the data as indexes into the palette. Stored left to right, top to bottom, no padding.
	ubyte[] data;

	override void clearInternal () nothrow @safe {
		palette = null;
		data = null;
		_width = _height = 0;
	}

	/// .
	override int width() const pure nothrow @safe @nogc {
		return _width;
	}

	/// .
	override int height() const pure nothrow @safe @nogc {
		return _height;
	}

	/// .
	override IndexedImage clone() const pure nothrow @safe {
		auto n = new IndexedImage(width, height);
		n.data[] = this.data[]; // the data member is already there, so array copy
		n.palette = this.palette.dup; // and here we need to allocate too, so dup
		n.hasAlpha = this.hasAlpha;
		return n;
	}

	override RGBA32 opIndex(size_t x, size_t y) const pure nothrow @safe @nogc {
		if (x >= 0 && y >= 0 && x < _width && y < _height) {
			size_t pos = cast(size_t)y*_width+x;
			if (pos >= data.length) return RGBA32(0, 0, 0, 0);
			ubyte b = data[pos];
			if (b >= palette.length) return RGBA32(0, 0, 0, 0);
			return palette[b];
		} else {
			return RGBA32(0, 0, 0, 0);
		}
	}

	override void opIndexAssign(in RGBA32 clr, size_t x, size_t y) @safe {
		if (x >= 0 && y >= 0 && x < _width && y < _height) {
			size_t pos = cast(size_t)y*_width+x;
			if (pos >= data.length) return;
			ubyte pidx = findNearestColor(palette, clr);
			if (palette.length < 255 &&
				 (palette[pidx].red != clr.red || palette[pidx].green != clr.green || palette[pidx].blue != clr.blue || palette[pidx].alpha != clr.alpha)) {
				// add new color
				pidx = addColor(clr);
			}
			data[pos] = pidx;
		}
	}

	private int _width;
	private int _height;

	/// .
	this(int w, int h) pure nothrow @safe {
		_width = w;
		_height = h;

        // ensure that the computed size does not exceed basic address space limits
        assert(cast(ulong)w * h  <= size_t.max);
        // upcast to avoid overflow for images larger than 536 Mpix
		data = new ubyte[cast(size_t)w*h];
	}

	/*
	void resize(int w, int h, bool scale) {

	}
	*/

	/// returns a new image
	override TrueColorImage getAsTrueColorImage() pure nothrow @safe {
		return convertToTrueColor();
	}

	/// Creates a new TrueColorImage based on this data
	TrueColorImage convertToTrueColor() const pure nothrow @safe {
		auto tci = new TrueColorImage(width, height);
		foreach(i, b; data) {
			tci.colours[i] = palette[b];
		}
		return tci;
	}

	/// Gets an exact match, if possible, adds if not. See also: the findNearestColor free function.
	ubyte getOrAddColor(RGBA32 c) nothrow @safe {
		foreach(i, co; palette) {
			if(c == co)
				return cast(ubyte) i;
		}

		return addColor(c);
	}

	/// Number of colors currently in the palette (note: palette entries are not necessarily used in the image data)
	int numColors() const pure nothrow @safe @nogc {
		return cast(int) palette.length;
	}

	/// Adds an entry to the palette, returning its index
	ubyte addColor(RGBA32 c) nothrow @safe pure {
		assert(palette.length < 256);
		if(c.alpha != 255)
			hasAlpha = true;
		palette ~= c;

		return cast(ubyte) (palette.length - 1);
	}
}

/// An RGBA array of image data. Use the free function quantize() to convert to an IndexedImage
class TrueColorImage : MemoryImage {
//	bool hasAlpha;
//	bool isGreyscale;

	/// .
	RGBA32[] colours; /// the data as rgba bytes. Stored left to right, top to bottom, no padding.

	int _width;
	int _height;

	override void clearInternal () nothrow @safe {// @nogc {
		colours = null;
		_width = _height = 0;
	}

	/// .
	override TrueColorImage clone() const pure nothrow @safe {
		auto n = new TrueColorImage(width, height);
		n.colours[] = this.colours[]; // copy into existing array ctor allocated
		return n;
	}

	/// .
	override int width() const pure nothrow @safe @nogc { return _width; }
	///.
	override int height() const pure nothrow @safe @nogc { return _height; }

	override RGBA32 opIndex(size_t x, size_t y) const pure nothrow @safe @nogc {
		if (x >= 0 && y >= 0 && x < _width && y < _height) {
			size_t pos = cast(size_t)y*_width+x;
			return colours[pos];
		} else {
			return RGBA32(0, 0, 0, 0);
		}
	}

	override void opIndexAssign(in RGBA32 clr, size_t x, size_t y) @safe {
		if (x >= 0 && y >= 0 && x < _width && y < _height) {
			size_t pos = cast(size_t)y*_width+x;
			if (pos < colours.length) colours[pos] = clr;
		}
	}

	/// .
	this(int w, int h) pure nothrow @safe {
		_width = w;
		_height = h;

		// ensure that the computed size does not exceed basic address space limits
        assert(cast(ulong)w * h * 4 <= size_t.max);
        // upcast to avoid overflow for images larger than 536 Mpix
		colours = new RGBA32[](cast(size_t)w * h);
	}

	/// Creates with existing data. The data pointer is stored here.
	this(int w, int h, ubyte[] data) pure nothrow @safe {
		_width = w;
		_height = h;
		assert(cast(ulong)w * h * 4 <= size_t.max);
		assert(data.length == cast(size_t)w * h * 4);
		colours = cast(RGBA32[])data;
	}

	/// Returns this
	override TrueColorImage getAsTrueColorImage() pure nothrow @safe {
		return this;
	}
}

/// Finds the best match for pixel in palette (currently by checking for minimum euclidean distance in rgb colorspace)
ubyte findNearestColor(in RGBA32[] palette, in RGBA32 pixel) nothrow pure @safe @nogc {
	int best = 0;
	int bestDistance = int.max;
	foreach(pe, co; palette) {
		auto dr = cast(int) co.red - pixel.red;
		auto dg = cast(int) co.green - pixel.green;
		auto db = cast(int) co.blue - pixel.blue;
		int dist = dr*dr + dg*dg + db*db;

		if(dist < bestDistance) {
			best = cast(int) pe;
			bestDistance = dist;
		}
	}

	return cast(ubyte) best;
}

/+
/// If the background is transparent, it simply erases the alpha channel.
void removeTransparency(IndexedImage img, Color background)
+/

/// Perform alpha-blending of `fore` to this color, return new color.
/// WARNING! This function does blending in RGB space, and RGB space is not linear!
RGBA32 alphaBlend(RGBA32 foreground, RGBA32 background) pure nothrow @safe @nogc {
	//if(foreground.a == 255)
		//return foreground;
	if(foreground.alpha == 0)
		return background; // the other blend function always returns alpha 255, but if the foreground has nothing, we should keep the background the same so its antialiasing doesn't get smashed (assuming this is blending in like a png instead of on a framebuffer)

	static if (__VERSION__ > 2067) pragma(inline, true);
	return background.alphaBlend(foreground);
}

/*
/// Reduces the number of colors in a palette.
void reducePaletteSize(IndexedImage img, int maxColors = 16) {

}
*/

// these are just really useful in a lot of places where the color/image functions are used,
// so I want them available with Color
/++
	2D location point
 +/
struct Point {
	int x; /// x-coordinate (aka abscissa)
	int y; /// y-coordinate (aka ordinate)

	pure const nothrow @safe:

	Point opBinary(string op)(in Point rhs) @nogc {
		return Point(mixin("x" ~ op ~ "rhs.x"), mixin("y" ~ op ~ "rhs.y"));
	}

	Point opBinary(string op)(int rhs) @nogc {
		return Point(mixin("x" ~ op ~ "rhs"), mixin("y" ~ op ~ "rhs"));
	}

	Size opCast(T : Size)() inout @nogc {
		return Size(x, y);
	}
}

///
struct Size {
	int width; ///
	int height; ///

	pure nothrow @safe:

	/++
		Rectangular surface area

		Calculates the surface area of a rectangle with dimensions equivalent to the width and height of the size.
	 +/
	int area() const @nogc { return width * height; }

	Point opCast(T : Point)() inout @nogc {
		return Point(width, height);
	}

	// gonna leave this undocumented for now since it might be removed later
	/+ +
		Adding (and other arithmetic operations) two sizes together will operate on the width and height independently. So Size(2, 3) + Size(4, 5) will give you Size(6, 8).
	+/
	Size opBinary(string op)(in Size rhs) const @nogc {
		return Size(
			mixin("width" ~ op ~ "rhs.width"),
			mixin("height" ~ op ~ "rhs.height"),
		);
	}

	Size opBinary(string op)(int rhs) const @nogc {
		return Size(
			mixin("width" ~ op ~ "rhs"),
			mixin("height" ~ op ~ "rhs"),
		);
	}
}

/++
	Calculates the linear offset of a point
	from the start (0/0) of a rectangle.

	This assumes that (0/0) is equivalent to offset `0`.
	Each step on the x-coordinate advances the resulting offset by `1`.
	Each step on the y-coordinate advances the resulting offset by `width`.

	This function is only defined for the 1st quadrant,
	i.e. both coordinates (x and y) of `pos` are positive.

	Returns:
		`y * width + x`

	History:
		Added December 19, 2023 (dub v11.4)
 +/
int linearOffset(const Point pos, const int width) @safe pure nothrow @nogc {
	return ((width * pos.y) + pos.x);
}

/// ditto
int linearOffset(const int width, const Point pos) @safe pure nothrow @nogc {
	return ((width * pos.y) + pos.x);
}

///
struct Rectangle {
	int left; ///
	int top; ///
	int right; ///
	int bottom; ///

	pure const nothrow @safe @nogc:

	///
	this(int left, int top, int right, int bottom) {
		this.left = left;
		this.top = top;
		this.right = right;
		this.bottom = bottom;
	}

	///
	this(in Point upperLeft, in Point lowerRight) {
		this(upperLeft.x, upperLeft.y, lowerRight.x, lowerRight.y);
	}

	///
	this(in Point upperLeft, in Size size) {
		this(upperLeft.x, upperLeft.y, upperLeft.x + size.width, upperLeft.y + size.height);
	}

	///
	Point upperLeft() {
		return Point(left, top);
	}

	///
	Point upperRight() {
		return Point(right, top);
	}

	///
	Point lowerLeft() {
		return Point(left, bottom);
	}

	///
	Point lowerRight() {
		return Point(right, bottom);
	}

	///
	Point center() {
		return Point((right + left) / 2, (bottom + top) / 2);
	}

	///
	Size size() {
		return Size(width, height);
	}

	///
	int width() {
		return right - left;
	}

	///
	int height() {
		return bottom - top;
	}

	/// Returns true if this rectangle entirely contains the other
	bool contains(in Rectangle r) {
		return contains(r.upperLeft) && contains(r.lowerRight);
	}

	/// ditto
	bool contains(in Point p) {
		return (p.x >= left && p.x < right && p.y >= top && p.y < bottom);
	}

	/// Returns true of the two rectangles at any point overlap
	bool overlaps(in Rectangle r) {
		// the -1 in here are because right and top are exclusive
		return !((right-1) < r.left || (r.right-1) < left || (bottom-1) < r.top || (r.bottom-1) < top);
	}

	/++
		Returns a Rectangle representing the intersection of this and the other given one.

		History:
			Added July 1, 2021
	+/
	Rectangle intersectionOf(in Rectangle r) {
		auto tmp = Rectangle(max(left, r.left), max(top, r.top), min(right, r.right), min(bottom, r.bottom));
		if(tmp.left >= tmp.right || tmp.top >= tmp.bottom)
			tmp = Rectangle.init;

		return tmp;
	}
}

/++
	A type to represent an angle, taking away ambiguity of if it wants degrees or radians.

	---
		Angle a = Angle.degrees(180);
		Angle b = Angle.radians(3.14159);

		// note there might be slight changes in precision due to internal conversions
	---

	History:
		Added August 29, 2023 (dub v11.1)
+/
struct Angle {
	private enum PI = 3.14159265358979;
	private float angle;

	pure @nogc nothrow @safe:

	private this(float angle) {
		this.angle = angle;
	}

	/++

	+/
	float degrees() const {
		return angle * 180.0 / PI;
	}

	/// ditto
	static Angle degrees(float deg) {
		return Angle(deg * PI / 180.0);
	}

	/// ditto
	float radians() const {
		return angle;
	}

	/// ditto
	static Angle radians(float rad) {
		return Angle(rad);
	}

	/++
		The +, -, +=, and -= operators all work on the angles too.
	+/
	Angle opBinary(string op : "+")(const Angle rhs) const {
		return Angle(this.angle + rhs.angle);
	}
	/// ditto
	Angle opBinary(string op : "-")(const Angle rhs) const {
		return Angle(this.angle + rhs.angle);
	}
	/// ditto
	Angle opOpAssign(string op : "+")(const Angle rhs) {
		return this.angle += rhs.angle;
	}
	/// ditto
	Angle opOpAssign(string op : "-")(const Angle rhs) {
		return this.angle -= rhs.angle;
	}

	// maybe sin, cos, tan but meh you can .radians on them too.
}

/++
	Implements a flood fill algorithm, like the bucket tool in
	MS Paint.

	Note it assumes `what.length == width*height`.

	Params:
		what = the canvas to work with, arranged as top to bottom, left to right elements
		width = the width of the canvas
		height = the height of the canvas
		target = the type to replace. You may pass the existing value if you want to do what Paint does
		replacement = the replacement value
		x = the x-coordinate to start the fill (think of where the user clicked in Paint)
		y = the y-coordinate to start the fill
		additionalCheck = A custom additional check to perform on each square before continuing. Returning true means keep flooding, returning false means stop. If null, it is not used.
+/
void floodFill(T)(
	T[] what, int width, int height, // the canvas to inspect
	T target, T replacement, // fill params
	int x, int y, bool delegate(int x, int y) @safe additionalCheck) // the node

	// in(what.length == width * height) // gdc doesn't support this syntax yet so not gonna use it until that comes out.
{
	assert(what.length == width * height); // will use the contract above when gdc supports it

	T node = what[y * width + x];

	if(target == replacement) return;

	if(node != target) return;

	if(additionalCheck is null)
		additionalCheck = (int, int) => true;

	if(!additionalCheck(x, y))
		return;

	Point[] queue;

	queue ~= Point(x, y);

	while(queue.length) {
		auto n = queue[0];
		queue = queue[1 .. $];
		//queue.assumeSafeAppend(); // lol @safe breakage

		auto w = n;
		int offset = cast(int) (n.y * width + n.x);
		auto e = n;
		auto eoffset = offset;
		w.x--;
		offset--;
		while(w.x >= 0 && what[offset] == target && additionalCheck(w.x, w.y)) {
			w.x--;
			offset--;
		}
		while(e.x < width && what[eoffset] == target && additionalCheck(e.x, e.y)) {
			e.x++;
			eoffset++;
		}

		// to make it inclusive again
		w.x++;
		offset++;
		foreach(o ; offset .. eoffset) {
			what[o] = replacement;
			if(w.y && what[o - width] == target && additionalCheck(w.x, w.y))
				queue ~= Point(w.x, w.y - 1);
			if(w.y + 1 < height && what[o + width] == target && additionalCheck(w.x, w.y))
				queue ~= Point(w.x, w.y + 1);
			w.x++;
		}
	}

	/+
	what[y * width + x] = replacement;

	if(x)
		floodFill(what, width, height, target, replacement,
			x - 1, y, additionalCheck);

	if(x != width - 1)
		floodFill(what, width, height, target, replacement,
			x + 1, y, additionalCheck);

	if(y)
		floodFill(what, width, height, target, replacement,
			x, y - 1, additionalCheck);

	if(y != height - 1)
		floodFill(what, width, height, target, replacement,
			x, y + 1, additionalCheck);
	+/
}
