///
module pixelmancy.colours.gradient;

import pixelmancy.colours.formats;
import pixelmancy.colours.utils;

/// A range-based smooth-ish linear gradient generator
struct Gradient {
	ulong index;
	ulong count;
	RGB24 start;
	RGB24 end;
	RGB24 front;
	void popFront() @safe pure {
		popFrontN(1);
	}
	void popFrontN(size_t steps) @safe pure {
		index += steps;
		double redInc = ((cast(double)end.red - cast(double)start.red) / cast(double)(count-1));
		double greenInc = ((cast(double)end.green - cast(double)start.green) / cast(double)(count-1));
		double blueInc = ((cast(double)end.blue - cast(double)start.blue) / cast(double)(count-1));
		front.red = cast(ubyte)(start.red + redInc * index);
		front.green = cast(ubyte)(start.green + greenInc * index);
		front.blue = cast(ubyte)(start.blue + blueInc * index);
	}
	bool empty() @safe pure {
		return index >= count;
	}
	this(T)(T from, T to, ulong steps) if(isColourFormat!T){
		count = steps;
		start = front = from.convert!RGB24;
		end = to.convert!RGB24;
	}
}
///
@safe pure unittest {
	import std.algorithm;
	import std.range;
	bool closeEnough(Range1, Range2)(Range1 a, Range2 b) {
		bool similar(uint v, uint v2) {
			return !!v.among(v2 - 1, v2, v2 + 1);
		}
		foreach (pair; zip(a,b)) {
			if (!similar(pair[0].red, pair[1].red) || !similar(pair[0].green, pair[1].green) || !similar(pair[0].blue, pair[1].blue)) {
				return false;
			}
		}
		return true;
	}
	assert(closeEnough(Gradient(RGB24(255,0,0), RGB24(0,0,255), 20),
		only(
			RGB24(255, 0, 0),
			RGB24(241, 0, 13),
			RGB24(228, 0, 26),
			RGB24(214, 0, 40),
			RGB24(201, 0, 53),
			RGB24(187, 0, 67),
			RGB24(174, 0, 80),
			RGB24(161, 0, 93),
			RGB24(147, 0, 107),
			RGB24(134, 0, 120),
			RGB24(120, 0, 134),
			RGB24(107, 0, 147),
			RGB24(93, 0, 161),
			RGB24(80, 0, 174),
			RGB24(67, 0, 187),
			RGB24(53, 0, 201),
			RGB24(40, 0, 214),
			RGB24(26, 0, 228),
			RGB24(13, 0, 241),
			RGB24(0, 0, 254)
		)
	));
}
