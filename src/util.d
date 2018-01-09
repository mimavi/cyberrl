import term;

byte[Key.max+1] key_to_x = [
	Key.digit_1: -1, Key.digit_2: 0, Key.digit_3: 1,
	Key.digit_4: -1, Key.digit_5: 0, Key.digit_6: 1,
	Key.digit_7: -1, Key.digit_8: 0, Key.digit_9: 1,
];

byte[Key.max+1] key_to_y = [
	Key.digit_1: 1, Key.digit_2: 1, Key.digit_3: 1,
	Key.digit_4: 0, Key.digit_5: 0, Key.digit_6: 0,
	Key.digit_7: -1, Key.digit_8: -1, Key.digit_9: -1,
];

char[Key.max+1] key_to_chr = [
	Key.digit_0: '0', 
	Key.digit_1: '1', Key.digit_2: '2', Key.digit_3: '3',
	Key.digit_4: '4', Key.digit_5: '5', Key.digit_6: '6',
	Key.digit_7: '7', Key.digit_8: '8', Key.digit_9: '9',
	Key.a: 'a', Key.b: 'b', Key.c: 'c', Key.d: 'd', Key.e: 'e',
	Key.f: 'f', Key.g: 'g', Key.h: 'h', Key.i: 'i', Key.j: 'j',
	Key.k: 'k', Key.l: 'l', Key.m: 'm', Key.n: 'n', Key.o: 'o',
	Key.p: 'p', Key.q: 'q', Key.r: 'r', Key.s: 's', Key.t: 't',
	Key.u: 'u', Key.v: 'v', Key.w: 'w', Key.x: 'x', Key.y: 'y',
	Key.z: 'z',
	Key.A: 'A', Key.B: 'B', Key.C: 'C', Key.D: 'D', Key.E: 'E',
	Key.F: 'F', Key.G: 'G', Key.H: 'H', Key.I: 'I', Key.J: 'J',
	Key.K: 'K', Key.L: 'L', Key.M: 'M', Key.N: 'N', Key.O: 'O',
	Key.P: 'P', Key.Q: 'Q', Key.R: 'R', Key.S: 'S', Key.T: 'T',
	Key.U: 'U', Key.V: 'V', Key.W: 'W', Key.X: 'X', Key.Y: 'Y',
	Key.Z: 'Z',
];

/*class Vec2
{
	int x, y;

	this(int x, int y) { this.x = x; this.y = y; }
}*/
