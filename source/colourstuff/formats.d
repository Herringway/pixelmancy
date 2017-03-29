module colourstuff.formats;

import std.algorithm;
import std.bitmanip;
import std.conv;
import std.range;

struct BGR555 { //XBBBBBGG GGGRRRRR
	enum redSize = 5;
	enum greenSize = 5;
	enum blueSize = 5;
	mixin(bitfields!(
		uint, "red", redSize,
		uint, "green", greenSize,
		uint, "blue", blueSize,
		bool, "padding", 1));
}
struct BGR565 { //BBBBBGGG GGGRRRRR
	enum redSize = 5;
	enum greenSize = 6;
	enum blueSize = 5;
	mixin(bitfields!(
		uint, "red", redSize,
		uint, "green", greenSize,
		uint, "blue", blueSize));
}
struct RGB888 { //RRRRRRRR GGGGGGGG BBBBBBBB
	enum redSize = 8;
	enum greenSize = 8;
	enum blueSize = 8;
	ubyte red;
	ubyte green;
	ubyte blue;
}
struct RGBA8888 { //RRRRRRRR GGGGGGGG BBBBBBBB AAAAAAAA
	enum redSize = 8;
	enum greenSize = 8;
	enum blueSize = 8;
	enum alphaSize = 8;
	ubyte red;
	ubyte green;
	ubyte blue;
	ubyte alpha;
}

RGB888 toRGB888(Format)(Format input) {
	RGB888 output;
	output.red = cast(ubyte)(input.red<<(8-Format.redSize));
	output.green = cast(ubyte)(input.green<<(8-Format.greenSize));
	output.blue = cast(ubyte)(input.blue<<(8-Format.blueSize));
	return output;
}
RGB888 fromHex(string colour) {
	RGB888 output;
	if (colour.front == '#') {
		colour.popFront();
	}
	if (colour.length == 3) {
		auto tmp = colour[0].repeat(2);
		output.red = tmp.parse!ubyte(16);
		tmp = colour[1].repeat(2);
		output.green = tmp.parse!ubyte(16);
		tmp = colour[2].repeat(2);
		output.blue = tmp.parse!ubyte(16);
	} else if (colour.length == 6) {
		auto tmp = colour[0..2];
		output.red = tmp.parse!ubyte(16);
		tmp = colour[2..4];
		output.green = tmp.parse!ubyte(16);
		tmp = colour[4..6];
		output.blue = tmp.parse!ubyte(16);
	}
	return output;
}
unittest {
	assert("#000000".fromHex == RGB888(0, 0, 0));
	assert("#FFFFFF".fromHex == RGB888(255, 255, 255));
	assert("FFFFFF".fromHex == RGB888(255, 255, 255));
	assert("#FFF".fromHex == RGB888(255, 255, 255));
	assert("#888".fromHex == RGB888(0x88, 0x88, 0x88));
	assert("888".fromHex == RGB888(0x88, 0x88, 0x88));
}