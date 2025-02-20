///
module tilemagic.colours.palette;

import tilemagic.colours.formats;

enum GameBoy = [
	RGB24(red: 155, green: 188, blue: 15),
	RGB24(red: 139, green: 172, blue: 15),
	RGB24(red: 48, green: 98, blue: 48),
	RGB24(red: 15, green: 56, blue: 15)
];

enum GameBoyPocket = [
	RGB24(red: 255, green: 255, blue: 255),
	RGB24(red: 170, green: 170, blue: 170),
	RGB24(red: 85, green: 85, blue: 85),
	RGB24(red: 0, green: 0, blue: 0)
];

/// Approximations of the colours used in NES games.
/// The NES does not actually use these, instead using NTSC/PAL waveforms directly.
/// See_Also: http://wiki.nesdev.com/w/index.php/NTSC_video
enum RGB24[16][4] NES2C02 = [
	[
		RGB24(red: 124, green: 124, blue: 124),
		RGB24(red: 0, green: 0, blue: 252),
		RGB24(red: 0, green: 0, blue: 188),
		RGB24(red: 68, green: 40, blue: 188),
		RGB24(red: 148, green: 0, blue: 132),
		RGB24(red: 168, green: 0, blue: 32),
		RGB24(red: 168, green: 16, blue: 0),
		RGB24(red: 136, green: 20, blue: 0),
		RGB24(red: 80, green: 48, blue: 0),
		RGB24(red: 0, green: 120, blue: 0),
		RGB24(red: 0, green: 104, blue: 0),
		RGB24(red: 0, green: 88, blue: 0),
		RGB24(red: 0, green: 64, blue: 88),
		RGB24(red: 0, green: 0, blue: 0),
		RGB24(red: 0, green: 0, blue: 0),
		RGB24(red: 0, green: 0, blue: 0),
	],
	[
		RGB24(red: 188, green: 188, blue: 188),
		RGB24(red: 0, green: 120, blue: 248),
		RGB24(red: 0, green: 88, blue: 248),
		RGB24(red: 104, green: 68, blue: 252),
		RGB24(red: 216, green: 0, blue: 204),
		RGB24(red: 228, green: 0, blue: 88),
		RGB24(red: 248, green: 56, blue: 0),
		RGB24(red: 228, green: 92, blue: 16),
		RGB24(red: 172, green: 124, blue: 0),
		RGB24(red: 0, green: 184, blue: 0),
		RGB24(red: 0, green: 168, blue: 0),
		RGB24(red: 0, green: 168, blue: 68),
		RGB24(red: 0, green: 136, blue: 136),
		RGB24(red: 0, green: 0, blue: 0),
		RGB24(red: 0, green: 0, blue: 0),
		RGB24(red: 0, green: 0, blue: 0),
	],
	[
		RGB24(red: 236, green: 238, blue: 236),
		RGB24(red: 76, green: 154, blue: 236),
		RGB24(red: 120, green: 124, blue: 236),
		RGB24(red: 176, green: 98, blue: 236),
		RGB24(red: 228, green: 84, blue: 236),
		RGB24(red: 236, green: 88, blue: 180),
		RGB24(red: 236, green: 106, blue: 100),
		RGB24(red: 212, green: 136, blue: 32),
		RGB24(red: 160, green: 170, blue: 0),
		RGB24(red: 116, green: 196, blue: 0),
		RGB24(red: 76, green: 208, blue: 32),
		RGB24(red: 56, green: 204, blue: 108),
		RGB24(red: 56, green: 180, blue: 204),
		RGB24(red: 60, green: 60, blue: 60),
	],
	[
		RGB24(red: 236, green: 238, blue: 236),
		RGB24(red: 168, green: 204, blue: 236),
		RGB24(red: 188, green: 188, blue: 236),
		RGB24(red: 212, green: 178, blue: 236),
		RGB24(red: 236, green: 174, blue: 236),
		RGB24(red: 236, green: 174, blue: 212),
		RGB24(red: 236, green: 180, blue: 176),
		RGB24(red: 228, green: 196, blue: 144),
		RGB24(red: 204, green: 210, blue: 120),
		RGB24(red: 180, green: 222, blue: 120),
		RGB24(red: 168, green: 226, blue: 144),
		RGB24(red: 152, green: 226, blue: 180),
		RGB24(red: 160, green: 214, blue: 228),
		RGB24(red: 160, green: 162, blue: 160),
	]
];

enum nesLum = [0.397, 0.681, 1, 1];
enum nesLum2 = [-0.117, 0, 0.308, 0.715];

enum CGA16 = [
	RGB24(red: 0, green: 0, blue: 0), //Black
	RGB24(red: 0, green: 0, blue: 170), //Blue
	RGB24(red: 0, green: 170, blue: 0), //Green
	RGB24(red: 0, green: 170, blue: 170), //Cyan
	RGB24(red: 170, green: 0, blue: 0), //Red
	RGB24(red: 170, green: 0, blue: 170), //Magenta
	RGB24(red: 170, green: 85, blue: 0), //Brown
	RGB24(red: 170, green: 170, blue: 170), //Light Gray
	RGB24(red: 85, green: 85, blue: 85), //Dark Gray
	RGB24(red: 85, green: 85, blue: 255), //Light Blue
	RGB24(red: 85, green: 255, blue: 85), //Light Green
	RGB24(red: 85, green: 255, blue: 255), //Light Cyan
	RGB24(red: 255, green: 85, blue: 85), //Light Red
	RGB24(red: 255, green: 85, blue: 255), //Light Magenta
	RGB24(red: 255, green: 255, blue: 85), //Yellow
	RGB24(red: 255, green: 255, blue: 255), //White
];
