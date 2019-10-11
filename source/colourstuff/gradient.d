module colourstuff.gradient;

import colourstuff.formats;
import colourstuff.utils;

struct Gradient {
	ulong index;
	ulong count;
	RGB888 start;
	RGB888 end;
	RGB888 front;
	void popFront() @safe pure {
		index++;
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
		start = front = from.convert!RGB888;
		end = to.convert!RGB888;
	}
}

@safe pure unittest {
	import std.algorithm;
	import std.range;
	assert(Gradient(RGB888(255,0,0), RGB888(0,0,255), 20).equal(
		only(
			RGB888(255, 0, 0),
			RGB888(241, 0, 13),
			RGB888(228, 0, 26),
			RGB888(214, 0, 40),
			RGB888(201, 0, 53),
			RGB888(187, 0, 67),
			RGB888(174, 0, 80),
			RGB888(161, 0, 93),
			RGB888(147, 0, 107),
			RGB888(134, 0, 120),
			RGB888(120, 0, 134),
			RGB888(107, 0, 147),
			RGB888(93, 0, 161),
			RGB888(80, 0, 174),
			RGB888(67, 0, 187),
			RGB888(53, 0, 201),
			RGB888(40, 0, 214),
			RGB888(26, 0, 228),
			RGB888(13, 0, 241),
			RGB888(0, 0, 254)
		)
	));
}
