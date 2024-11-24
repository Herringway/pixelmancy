module tilemagic.util;

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
	alias opApply = opApplyImplC!(int delegate(size_t x, size_t y, const E element));
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

	(cast(Array2D!(ushort[2]))tmp)[2,1] = [1, 2];
	assert(tmp[2, 1] == 0x00020001);
	immutable tmp2 = (cast(immutable Array2D!(ushort[2]))tmp);
	assert(tmp2[2,1] == [1,2]);
}

auto array2D(T)(return T[] array, size_t width, size_t height) {
	return Array2D!T(width, height, array);
}
