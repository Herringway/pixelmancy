module magicalrainbows.palette;

import magicalrainbows.formats;

enum GameBoy = [
	RGB888(155, 188, 15),
	RGB888(139, 172, 15),
	RGB888(48, 98, 48),
	RGB888(15, 56, 15)
];

enum GameBoyPocket = [
	RGB888(255, 255, 255),
	RGB888(170, 170, 170),
	RGB888(85, 85, 85),
	RGB888(0, 0, 0)
];

/// Approximations of the colours used in NES games.
/// The NES does not actually use these, instead using NTSC/PAL waveforms
/// directly.
/// See_Also: http://wiki.nesdev.com/w/index.php/NTSC_video
enum RGB888[16][4] NES2C02 = [
	[
		RGB888(124, 124, 124),
		RGB888(0, 0, 252),
		RGB888(0, 0, 188),
		RGB888(68, 40, 188),
		RGB888(148, 0, 132),
		RGB888(168, 0, 32),
		RGB888(168, 16, 0),
		RGB888(136, 20, 0),
		RGB888(80, 48, 0),
		RGB888(0, 120, 0),
		RGB888(0, 104, 0),
		RGB888(0, 88, 0),
		RGB888(0, 64, 88),
		RGB888(0, 0, 0),
		RGB888(0, 0, 0),
		RGB888(0, 0, 0),
	],
	[
		RGB888(188, 188, 188),
		RGB888(0, 120, 248),
		RGB888(0, 88, 248),
		RGB888(104, 68, 252),
		RGB888(216, 0, 204),
		RGB888(228, 0, 88),
		RGB888(248, 56, 0),
		RGB888(228, 92, 16),
		RGB888(172, 124, 0),
		RGB888(0, 184, 0),
		RGB888(0, 168, 0),
		RGB888(0, 168, 68),
		RGB888(0, 136, 136),
		RGB888(0, 0, 0),
		RGB888(0, 0, 0),
		RGB888(0, 0, 0),
	],
	[
		RGB888(236, 238, 236),
		RGB888(76, 154, 236),
		RGB888(120, 124, 236),
		RGB888(176, 98, 236),
		RGB888(228, 84, 236),
		RGB888(236, 88, 180),
		RGB888(236, 106, 100),
		RGB888(212, 136, 32),
		RGB888(160, 170, 0),
		RGB888(116, 196, 0),
		RGB888(76, 208, 32),
		RGB888(56, 204, 108),
		RGB888(56, 180, 204),
		RGB888(60, 60, 60),
	],
	[
		RGB888(236, 238, 236),
		RGB888(168, 204, 236),
		RGB888(188, 188, 236),
		RGB888(212, 178, 236),
		RGB888(236, 174, 236),
		RGB888(236, 174, 212),
		RGB888(236, 180, 176),
		RGB888(228, 196, 144),
		RGB888(204, 210, 120),
		RGB888(180, 222, 120),
		RGB888(168, 226, 144),
		RGB888(152, 226, 180),
		RGB888(160, 214, 228),
		RGB888(160, 162, 160),
	]
];

enum nesLum = [0.397, 0.681, 1, 1];
enum nesLum2 = [-0.117, 0, 0.308, 0.715];

enum CGA16 = [
	RGB888(0, 0, 0), //Black
	RGB888(0, 0, 170), //Blue
	RGB888(0, 170, 0), //Green
	RGB888(0, 170, 170), //Cyan
	RGB888(170, 0, 0), //Red
	RGB888(170, 0, 170), //Magenta
	RGB888(170, 85, 0), //Brown
	RGB888(170, 170, 170), //Light Gray
	RGB888(85, 85, 85), //Dark Gray
	RGB888(85, 85, 255), //Light Blue
	RGB888(85, 255, 85), //Light Green
	RGB888(85, 255, 255), //Light Cyan
	RGB888(255, 85, 85), //Light Red
	RGB888(255, 85, 255), //Light Magenta
	RGB888(255, 255, 85), //Yellow
	RGB888(255, 255, 255), //White
];
