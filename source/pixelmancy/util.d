module pixelmancy.util;

// from D documentation
struct Array2D(E) {
	import std.format : format;
	import std.traits : isMutable;
	private E[] impl;
	size_t stride;
	size_t width, height;

	this(size_t width, size_t height) inout {
		this(width, height, width);
	}

	this(size_t width, size_t height, size_t stride) inout {
		this(width, height, stride, new inout E[](width * height));
	}

	this(size_t width, size_t height, inout E[] initialData) inout {
		this(width, height, width, initialData);
	}

	this(size_t width, size_t height, size_t stride, inout E[] initialData) inout
		in(initialData.length == stride * height, format!"Base array has invalid length %s, expecting %s"(initialData.length, stride * height))
	{
		impl = initialData;
		this.stride = stride;
		this.width = width;
		this.height = height;
	}
	size_t[2] dimensions() const @safe pure {
		return [opDollar!0, opDollar!1];
	}

	// Index a single element, e.g., arr[0, 1]
	ref inout(E) opIndex(size_t i, size_t j) inout {
		return impl[i + stride * j];
	}

	// Array slicing, e.g., arr[1..2, 1..2], arr[2, 0..$], arr[0..$, 1].
	inout(Array2D) opIndex(size_t[2] r1, size_t[2] r2) inout
		in(r1[0] <= width, format!"slice [%s..%s] extends beyond array of width %s"(r1[0], r1[1], width))
		in(r1[1] <= width, format!"slice [%s..%s] extends beyond array of width %s"(r1[0], r1[1], width))
		in(r2[0] <= height, format!"slice [%s..%s] extends beyond array of height %s"(r2[0], r2[1], height))
		in(r2[1] <= height, format!"slice [%s..%s] extends beyond array of height %s"(r2[0], r2[1], height))
	{
		auto startOffset = r1[0] + r2[0] * stride;
		auto endOffset = r1[1] + (r2[1] - 1) * stride;

		return (inout Array2D)(r1[1] - r1[0], r2[1] - r2[0], stride, this.impl[startOffset .. (endOffset / stride + !!(endOffset % stride)) * stride]);
	}
	auto opIndex(size_t[2] r1, size_t j) inout {
		return opIndex(r1, [j, j + 1]).impl[0 .. stride];
	}
	auto opIndex(size_t i, size_t[2] r2) inout {
		return opIndex([i, i + 1], r2);
	}
	auto opIndex() inout {
		return impl;
	}
	static if (isMutable!E) {
		auto opAssign(E element) {
			impl[] = element;
		}
		void opIndexAssign(E elem) {
			impl[] = elem;
		}
		void opIndexAssign(E[] elem) {
			impl[] = elem;
		}
		void opIndexAssign(E elem, size_t i, size_t j)
			in(i < width, format!"index [%s] is out of bounds for array of width %s"(i, width))
			in(j < height, format!"index [%s] is out of bounds for array of height %s"(j, height))
		{
			impl[i + stride * j] = elem;
		}
		void opIndexAssign(E elem, size_t[2] i, size_t[2] j)
			in(i[0] <= width, format!"slice [%s..%s] extends beyond array of width %s"(i[0], i[1], width))
			in(i[1] <= width, format!"slice [%s..%s] extends beyond array of width %s"(i[0], i[1], width))
			in(j[0] <= height, format!"slice [%s..%s] extends beyond array of height %s"(j[0], j[1], height))
			in(j[1] <= height, format!"slice [%s..%s] extends beyond array of height %s"(j[0], j[1], height))
		{
			foreach (row; j[0] .. j[1]) {
				impl[row * stride + i[0] .. row * stride + i[1]] = elem;
			}
		}
		void opIndexAssign(E elem, size_t i, size_t[2] j) {
			opIndexAssign(elem, [i, i+1], j);
		}
		void opIndexAssign(E[] elements, size_t i, size_t[2] j) {
			foreach (idx, element; elements) {
				this[i, j[0] + idx] = element;
			}
		}
		void opIndexAssign(E[] elements, size_t[2] i, size_t j) {
			impl[j * stride + i[0] .. j * stride + i[1]] = elements;
		}
		void opIndexAssign(E elem, size_t[2] i, size_t j) {
			opIndexAssign(elem, i, [j, j+1]);
		}
	}
	Array2D!NewElement opCast(T : Array2D!NewElement, NewElement)() if (NewElement.sizeof == E.sizeof) {
		return Array2D!NewElement(width, height, stride, cast(NewElement[])impl);
	}

	// Support for `x..y` notation in slicing operator for the given dimension.
	size_t[2] opSlice(size_t dim)(size_t start, size_t end) const
	if (dim >= 0 && dim < 2)
	in(start >= 0 && end <= this.opDollar!dim)
	{
		return [start, end];
	}

	// Support `$` in slicing notation, e.g., arr[1..$, 0..$-1].
	size_t opDollar(size_t dim : 0)() const {
		return width;
	}
	size_t opDollar(size_t dim : 1)() const {
		return height;
	}
	void toString(R)(ref R sink) const {
		import std.format : formattedWrite;
		foreach (row; 0 .. height) {
			sink.formattedWrite!"%s\n"(this[0 .. $, row]);
		}
	}
	alias opApply = opApplyImpl!(int delegate(size_t x, size_t y, ref E element) @system);
	alias opApply = opApplyImpl!(int delegate(size_t x, size_t y, ref E element) @system pure);
	alias opApply = opApplyImpl!(int delegate(size_t x, size_t y, ref E element) @safe);
	alias opApply = opApplyImpl!(int delegate(size_t x, size_t y, ref E element) @safe pure);
	int opApplyImpl(DG)(scope DG dg) {
		foreach (iterY; 0 .. height) {
			foreach (iterX, ref elem; this[0 .. $, iterY][]) {
				auto result = dg(iterX, iterY, elem);
				if (result) {
					return result;
				}
			}
		}
		return 0;
	}
	alias opApply = opApplyImplC!(int delegate(size_t x, size_t y, const E element) @system);
	alias opApply = opApplyImplC!(int delegate(size_t x, size_t y, const E element) @system pure);
	alias opApply = opApplyImplC!(int delegate(size_t x, size_t y, const E element) @safe);
	alias opApply = opApplyImplC!(int delegate(size_t x, size_t y, const E element) @safe pure);
	int opApplyImplC(DG)(scope DG dg) const {
		foreach (iterY; 0 .. height) {
			foreach (iterX, ref elem; this[0 .. $, iterY][]) {
				auto result = dg(iterX, iterY, elem);
				if (result) {
					return result;
				}
			}
		}
		return 0;
	}
	auto toSiryulType()() const @safe {
		import std.algorithm.iteration : map;
		import std.array : array;
		import std.range : chunks;
		return this[].chunks(width).map!(x => x.array).array;
	}
	static Array2D fromSiryulType()(E[][] val) @safe {
		import std.array : join;
		return Array2D(val[0].length, val.length, val.join());
	}
}


@safe pure unittest {
	import std.array : array;
	import std.range : iota;
	auto tmp = Array2D!int(5, 6, iota(5*6).array);
	assert(tmp[2, 1] == 7);
	assert(tmp[$ - 1, $ - 1] == 29);
	assert(tmp[0 .. $, 0] == [0, 1, 2, 3, 4]);
	assert(tmp[0 .. $, 5] == [25, 26, 27, 28, 29]);
	assert(tmp[0, 0 .. $][0, 2] == 10);

	tmp = 42;
	assert(tmp[2, 1] == 42);
	tmp[0 .. 2, 0 .. 2] = 31;
	assert(tmp[1, 1] == 31);
	assert(tmp[2, 2] == 42);
	tmp[0, 0 .. 2] = 18;
	assert(tmp[0, 1] == 18);
	assert(tmp[1, 1] == 31);
	tmp[0 .. 2, 0] = 77;
	assert(tmp[1, 0] == 77);
	assert(tmp[1, 1] == 31);

	tmp[0 .. $, 4] = [100, 101, 102, 103, 104];
	assert(tmp[0, 4] == 100);
	assert(tmp[$ - 1, 4] == 104);

	tmp[4, 0 .. $] = [200, 201, 202, 203, 204, 205];
	assert(tmp[4, 0] == 200);
	assert(tmp[4, $ - 1] == 205);

	(cast(Array2D!(ushort[2]))tmp)[2,1] = [1, 2];
	assert(tmp[2, 1] == 0x00020001);
	immutable tmp2 = (cast(immutable Array2D!(ushort[2]))tmp);
	assert(tmp2[2,1] == [1,2]);
}

auto array2D(T)(return T[] array, size_t width, size_t height) {
	return Array2D!T(width, height, array);
}

struct StaticArray2D(E, size_t inWidth, size_t inHeight, size_t inStride = inWidth) {
	import std.format : format;
	import std.traits : isMutable;
	enum stride = inStride;
	enum width = inWidth;
	enum height = inHeight;
	align(1):
	private E[stride * height] impl;

	size_t[2] dimensions() const @safe pure {
		return [opDollar!0, opDollar!1];
	}

	// Index a single element, e.g., arr[0, 1]
	ref inout(E) opIndex(size_t i, size_t j) inout {
		return impl[i + stride * j];
	}

	// Array slicing, e.g., arr[1..2, 1..2], arr[2, 0..$], arr[0..$, 1].
	inout(Array2D!E) opIndex(size_t[2] r1, size_t[2] r2) inout
		in(r1[0] <= width, format!"slice [%s..%s] extends beyond array of width %s"(r1[0], r1[1], width))
		in(r1[1] <= width, format!"slice [%s..%s] extends beyond array of width %s"(r1[0], r1[1], width))
		in(r2[0] <= height, format!"slice [%s..%s] extends beyond array of height %s"(r2[0], r2[1], height))
		in(r2[1] <= height, format!"slice [%s..%s] extends beyond array of height %s"(r2[0], r2[1], height))
	{
		auto startOffset = r1[0] + r2[0] * stride;
		auto endOffset = r1[1] + (r2[1] - 1) * stride;

		return (inout Array2D!E)(r1[1] - r1[0], r2[1] - r2[0], stride, this.impl[startOffset .. (endOffset / stride + !!(endOffset % stride)) * stride]);
	}
	auto opIndex(size_t[2] r1, size_t j) inout {
		return opIndex(r1, [j, j + 1]).impl[0 .. stride];
	}
	auto opIndex(size_t i, size_t[2] r2) inout {
		return opIndex([i, i + 1], r2);
	}
	auto opIndex() inout {
		return impl;
	}
	static if (isMutable!E) {
		auto opAssign(E element) {
			impl[] = element;
		}
		void opIndexAssign(E elem) {
			impl[] = elem;
		}
		void opIndexAssign(E[] elem) {
			impl[] = elem;
		}
		void opIndexAssign(E elem, size_t i, size_t j)
			in(i < width, format!"index [%s] is out of bounds for array of width %s"(i, width))
			in(j < height, format!"index [%s] is out of bounds for array of height %s"(j, height))
		{
			impl[i + stride * j] = elem;
		}
		void opIndexAssign(E elem, size_t[2] i, size_t[2] j)
			in(i[0] <= width, format!"slice [%s..%s] extends beyond array of width %s"(i[0], i[1], width))
			in(i[1] <= width, format!"slice [%s..%s] extends beyond array of width %s"(i[0], i[1], width))
			in(j[0] <= height, format!"slice [%s..%s] extends beyond array of height %s"(j[0], j[1], height))
			in(j[1] <= height, format!"slice [%s..%s] extends beyond array of height %s"(j[0], j[1], height))
		{
			foreach (row; j[0] .. j[1]) {
				impl[row * stride + i[0] .. row * stride + i[1]] = elem;
			}
		}
		void opIndexAssign(E elem, size_t i, size_t[2] j) {
			opIndexAssign(elem, [i, i+1], j);
		}
		void opIndexAssign(E elem, size_t[2] i, size_t j) {
			opIndexAssign(elem, i, [j, j+1]);
		}
	}
	StaticArray2D!(NewElement, width, height, stride) opCast(T : StaticArray2D!(NewElement, width, height, stride), NewElement)() if (NewElement.sizeof == E.sizeof) {
		return StaticArray2D!(NewElement, width, height, stride)(cast(NewElement[height * stride])impl);
	}

	// Support for `x..y` notation in slicing operator for the given dimension.
	size_t[2] opSlice(size_t dim)(size_t start, size_t end) const
	if (dim >= 0 && dim < 2)
	in(start >= 0 && end <= this.opDollar!dim)
	{
		return [start, end];
	}

	// Support `$` in slicing notation, e.g., arr[1..$, 0..$-1].
	size_t opDollar(size_t dim : 0)() const {
		return width;
	}
	size_t opDollar(size_t dim : 1)() const {
		return height;
	}
	void toString(R)(ref R sink) const {
		import std.format : formattedWrite;
		foreach (row; 0 .. height) {
			sink.formattedWrite!"%s\n"(this[0 .. $, row]);
		}
	}
	alias opApply = opApplyImpl!(int delegate(size_t x, size_t y, ref E element));
	int opApplyImpl(DG)(scope DG dg) {
		foreach (iterY; 0 .. height) {
			foreach (iterX, ref elem; this[0 .. $, iterY][]) {
				auto result = dg(iterX, iterY, elem);
				if (result) {
					return result;
				}
			}
		}
		return 0;
	}
}

@safe pure unittest {
	import std.array : array;
	import std.range : iota;
	auto tmp = StaticArray2D!(int, 5, 6)(iota(5*6).array[0 .. 5 * 6]);
	assert(tmp[2, 1] == 7);
	assert(tmp[$ - 1, $ - 1] == 29);
	assert(tmp[0 .. $, 0] == [0, 1, 2, 3, 4]);
	assert(tmp[0 .. $, 5] == [25, 26, 27, 28, 29]);
	assert(tmp[0, 0 .. $][0, 2] == 10);

	tmp = 42;
	assert(tmp[2, 1] == 42);
	tmp[0 .. 2, 0 .. 2] = 31;
	assert(tmp[1, 1] == 31);
	assert(tmp[2, 2] == 42);
	tmp[0, 0 .. 2] = 18;
	assert(tmp[0, 1] == 18);
	assert(tmp[1, 1] == 31);
	tmp[0 .. 2, 0] = 77;
	assert(tmp[1, 0] == 77);
	assert(tmp[1, 1] == 31);

	const castCopy = (cast(StaticArray2D!(ushort[2], 5, 6))tmp);
	assert(castCopy[2, 1] == [42, 0]);
	immutable tmp2 = (cast(immutable StaticArray2D!(ushort[2], 5, 6))tmp);
	assert(tmp2[2,1] == [42, 0]);
}

private struct EndianType(T, bool littleEndian) {
	import std.range : isOutputRange;
	ubyte[T.sizeof] raw;
	alias this = native;
	version(BigEndian) {
		enum needSwap = littleEndian;
	} else {
		enum needSwap = !littleEndian;
	}
	T native() const @safe {
		T result = (cast(T[])(raw[].dup))[0];
		static if (needSwap) {
			swapEndianness(result);
		}
		return result;
	}
	void native(out T result) const @safe {
		result = (cast(T[])(raw[].dup))[0];
		static if (needSwap) {
			swapEndianness(result);
		}
	}
	void toString(Range)(Range sink) const if (isOutputRange!(Range, const(char))) {
		import std.format : formattedWrite;
		sink.formattedWrite!"%s"(this.native);
	}
	void opAssign(ubyte[T.sizeof] input) {
		raw = input;
	}
	void opAssign(ubyte[] input) {
		assert(input.length == T.sizeof, "Array must be "~T.sizeof.stringof~" bytes long");
		raw = input;
	}
	void opAssign(T input) @safe {
		static if (needSwap) {
			swapEndianness(input);
		}
		union Raw {
			T val;
			ubyte[T.sizeof] raw;
		}
		raw = Raw(input).raw;
	}
}

void swapEndianness(T)(ref T val) {
	import std.traits : isBoolean, isFloatingPoint, isIntegral, isSomeChar, isStaticArray;
	import std.bitmanip : swapEndian;
	static if (isIntegral!T || isSomeChar!T || isBoolean!T) {
		val = swapEndian(val);
	} else static if (isFloatingPoint!T) {
		import std.algorithm : reverse;
		union Raw {
			T val;
			ubyte[T.sizeof] raw;
		}
		auto raw = Raw(val);
		reverse(raw.raw[]);
		val = raw.val;
	} else static if (is(T == struct)) {
		foreach (ref field; val.tupleof) {
			swapEndianness(field);
		}
	} else static if (isStaticArray!T) {
		foreach (ref element; val) {
			swapEndianness(element);
		}
	} else static assert(0, "Unsupported type "~T.stringof);
}

/++
+ Represents a little endian type. Most significant bits come last, so 0x4000
+ is, for example, represented as [00, 04].
+/
alias LittleEndian(T) = EndianType!(T, true);
///
@safe unittest {
	import std.conv : text;
	LittleEndian!ushort x;
	x = cast(ubyte[])[0, 2];
	assert(x == 0x200);
	ushort tmp;
	x.native(tmp);
	assert(tmp == 512);
	assert(x.text == "512");
	ubyte[] z = [0, 3];
	x = z;
	assert(x == 0x300);
	assert(x.text == "768");
	x = 1024;
	assert(x.raw == [0, 4]);

	LittleEndian!float f;
	f = cast(ubyte[])[0, 0, 32, 64];
	assert(f == 2.5);

	align(1) static struct Test {
		align(1):
		uint a;
		ushort b;
		ushort[2] c;
	}
	LittleEndian!Test t;
	t = cast(ubyte[])[3, 2, 1, 0, 2, 1, 6, 5, 8, 7];
	assert(t.a == 0x010203);
	assert(t.b == 0x0102);
	assert(t.c == [0x0506, 0x0708]);
	t = Test(42, 42, [10, 20]);
	assert(t.raw == [42, 0, 0, 0, 42, 0, 10, 0, 20, 0]);

	align(1) static struct Test2 {
		align(1):
		ubyte a;
		char b;
		ubyte[4] c;
	}
	LittleEndian!Test2 t2;
	t2 = cast(ubyte[])[20, 30, 1, 2, 3, 4];
	assert(t2.a == 20);
	assert(t2.b == 30);
	assert(t2.c == [1, 2, 3, 4]);
}

/++
+ Represents a big endian type. Most significant bits come first, so 0x4000
+ is, for example, represented as [04, 00].
+/
alias BigEndian(T) = EndianType!(T, false);
///
@safe unittest {
	import std.conv : text;
	BigEndian!ushort x;
	x = cast(ubyte[])[2, 0];
	assert(x == 0x200);
	ushort tmp;
	x.native(tmp);
	assert(tmp == 512);
	assert(x.text == "512");
	x = 1024;
	assert(x.raw == [4, 0]);

	BigEndian!float f;
	f = cast(ubyte[])[64, 32, 0, 0];
	assert(f == 2.5);

	align(1) static struct Test {
		align(1):
		uint a;
		ushort b;
		ushort[2] c;
	}
	BigEndian!Test t;
	t = cast(ubyte[])[0, 1, 2, 3, 1, 2, 5, 6, 7, 8];
	assert(t.a == 0x010203);
	assert(t.b == 0x0102);
	assert(t.c == [0x0506, 0x0708]);
	t = Test(42, 42, [10, 20]);
	assert(t.raw == [0, 0, 0, 42, 0, 42, 0, 10, 0, 20]);

	align(1) static struct Test2 {
		align(1):
		ubyte a;
		char b;
		ubyte[4] c;
	}
	BigEndian!Test2 t2;
	t2 = cast(ubyte[])[20, 30, 1, 2, 3, 4];
	assert(t2.a == 20);
	assert(t2.b == 30);
	assert(t2.c == [1, 2, 3, 4]);
}
public import std.bitmanip : peek, read;

/// Reads a struct from the given range. The range is not consumed.
T peek(T)(const(ubyte)[] range) if (is(T == struct)) {
	return (cast(T[1])range[0 .. T.sizeof])[0];
}

/// Reads a struct from the given range. T.sizeof bytes of range are consumed.
T read(T)(ref const(ubyte)[] range) if (is(T == struct)) {
	scope(exit) range = range[T.sizeof .. $];
	return range.peek!T();
}
