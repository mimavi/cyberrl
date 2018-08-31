debug {
	public import std.stdio;
}
import std.container;
import std.format;
import std.datetime;
import std.random;
import std.math;
import std.traits;
import std.array;
import std.stdio;
import ser;
import term;

// TODO: Add unittests.

/*immutable int[Key.max+1] key_to_x = [
	Key.digit_1: -1, Key.digit_2: 0, Key.digit_3: 1,
	Key.digit_4: -1, Key.digit_5: 0, Key.digit_6: 1,
	Key.digit_7: -1, Key.digit_8: 0, Key.digit_9: 1,
];
immutable int[Key.max+1] key_to_y = [
	Key.digit_1: 1, Key.digit_2: 1, Key.digit_3: 1,
	Key.digit_4: 0, Key.digit_5: 0, Key.digit_6: 0,
	Key.digit_7: -1, Key.digit_8: -1, Key.digit_9: -1,
];*/

immutable Point[Key.max+1] key_to_point = [
	Key.digit_1: Point(-1, 1),
	Key.digit_2: Point(0, 1),
	Key.digit_3: Point(1, 1),
	Key.digit_4: Point(-1, 0),
	Key.digit_5: Point(0, 0),
	Key.digit_6: Point(1, 0),
	Key.digit_7: Point(-1, -1),
	Key.digit_8: Point(0, -1),
	Key.digit_9: Point(1, -1),
];

// Note: modulo addition or substraction of 2 causes a 90 degree turn.
immutable Point[Dir.max+1] dir_to_point = [
	Dir.down_left: Point(-1, 1),
	Dir.down: Point(0, 1),
	Dir.down_right: Point(1, 1),
	Dir.left: Point(-1, 0),
	Dir.center: Point(0, 0),
	Dir.right: Point(1, 0),
	Dir.up_left: Point(-1, -1),
	Dir.up: Point(0, -1),
	Dir.up_right: Point(1, -1),
];


immutable char[Key.max+1] key_to_chr = [
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

immutable int[255] chr_to_index = [
	'a': 0,  'b': 1,  'c': 2,  'd': 3,  'e': 4,  'f': 5,  'g': 6,  'h': 7,
	'i': 8,  'j': 9,  'k': 10, 'l': 11, 'm': 12, 'n': 13, 'o': 14, 'p': 15,
	'q': 16, 'r': 17, 's': 18, 't': 19, 'u': 20, 'v': 21, 'w': 22, 'x': 23,
	'y': 24, 'z': 25,
	'A': 26, 'B': 27, 'C': 28, 'D': 29, 'E': 30, 'F': 31, 'G': 32, 'H': 33,
	'I': 34, 'J': 35, 'K': 36, 'L': 37, 'M': 38, 'N': 39, 'O': 40, 'P': 41,
	'Q': 42, 'R': 43, 'S': 44, 'T': 45, 'U': 46, 'V': 47, 'W': 48, 'X': 49,
	'Y': 50, 'Z': 51,
	'0': 52, '1': 53, '2': 54, '3': 55, '4': 56, '5': 57, '6': 58, '7': 59,
	'8': 60, '9': 61
];

immutable char[chr_to_index.length] index_to_chr = [
	0:  'a', 1:  'b', 2:  'c', 3:  'd', 4:  'e', 5:  'f', 6:  'g', 7:  'h',
	8:  'i', 9:  'j', 10: 'k', 11: 'l', 12: 'm', 13: 'n', 14: 'o', 15: 'p',
	16: 'q', 17: 'r', 18: 's', 19: 't', 20: 'u', 21: 'v', 22: 'w', 23: 'x',
	24: 'y', 25: 'z',
	26: 'a', 27: 'b', 28: 'c', 29: 'd', 30: 'e', 31: 'f', 32: 'g', 33: 'h',
	34: 'i', 35: 'j', 36: 'k', 37: 'l', 38: 'm', 39: 'n', 40: 'o', 41: 'p',
	42: 'q', 43: 'r', 44: 's', 45: 't', 46: 'u', 47: 'v', 48: 'w', 49: 'x',
	50: 'y', 51: 'z',
	52: '0', 53: '1', 54: '2', 55: '3', 56: '4', 57: '5', 58: '6', 59: '7',
	60: '8', 61: '9',
];

immutable string[int] val_to_minus_5_to_5_adjective;
immutable string[int] val_to_0_to_5_adjective;
// XXX: Perhaps use array instead of associative array.
immutable Dir[Dir] turn_dir_left;
immutable Dir[Dir] turn_dir_right;

Random rng;

enum Dir
{
	down_left,
	down,
	down_right,
	left,
	center,
	right,
	up_left,
	up,
	up_right,
}

// XXX: Renaming it to `Vector` could make sense.
struct Point
{
	mixin Serializable;
	int x, y;

	this(Serializer serializer) {}
	this(int x, int y) { this.x = x; this.y = y; }

	void beforesave(Serializer serializer) {}
	void beforeload(Serializer serializer) {}
	void aftersave(Serializer serializer) {}
	void afterload(Serializer serializer) {}

	Point opUnary(string op)(Point p)
	{
		static if (op == "-") {
			return Point(-p.x, -p.y);
		}
	}

	Point opBinary(string op)(Point p1, Point p2)
	{
		static if (op == "+") {
			return Point(p1.x+p2.x, p1.y+p2.y);
		} static if (op == "-") {
			return Point(p1.x-p2.x, p1.y-p2.y);
		}
	}
}

// "AaRect" stands for "axis-aligned rectangle".
struct AaRect
{
	int x, y, width, height;
	this(int x, int y, int width, int height)
	{
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}

	bool get_is_inside(int x, int y)
	{
		return x >= this.x && y >= this.y
		&& x <= this.x+width-1 && y <= this.y+height-1;
	}
	bool get_is_inside(Point p) { return get_is_inside(p.x, p.y); }
}

template hasAddress(alias T)
{
	// HACK!
	static if (__traits(compiles, (ref typeof(T) x) {} (T))) {
		enum hasAddress = true;
	} else {
		enum hasAddress = false;
	}
}

static this()
{
	val_to_minus_5_to_5_adjective = [
		-5: "extremely low",
		-4: "incredibly low",
		-3: "very low",
		-2: "low",
		-1: "below average",
		0: "average",
		1: "above average",
		2: "high",
		3: "very high",
		4: "incredibly high",
		5: "extremely high",
	];
	val_to_0_to_5_adjective = [
		0: "unskilled in",
		1: "novice in",
		2: "skilled in",
		3: "accomplished in",
		4: "excellent in",
		5: "master in",
	];
	turn_dir_left = [
		Dir.right: Dir.up,
		Dir.up: Dir.left,
		Dir.left: Dir.down,
		Dir.down: Dir.right,
	];
	turn_dir_right = [
		Dir.right: Dir.down,
		Dir.down: Dir.left,
		Dir.left: Dir.up,
		Dir.up: Dir.right,
	];

	rng = Random(cast(uint)Clock.currTime().fracSecs().total!"hnsecs");
}

string[] splitAtSpaces(string str, int width)
{
	string[] results;
	if (str.length <= width) {
		return [str];
	}
	for (int crack = 0; str.length >= width; str = str[crack+1..$]) {
		crack = getSplitAtSpace(str, width);
		if (crack == -1) {
			return [];
		}
		++results.length;
		results[$-1] = str[0..crack];
	}
	if (str.length > 0) {
		++results.length;
		results[$-1] = str;
	}
	return results;
}

// Returns -1 if splitting fails.
int getSplitAtSpace(string str, int width)
{
	//if (str[width-1] != ' ' && str[width] != ' ') {
	if (str.length < width) {
		return cast(int)str.length;
	}
	if (str[width-1] == ' ') {
		return width-1;
	}
	if (str[width] == ' ') {
		return width;
	}
	foreach (i; 0..width-2) {
		if (str[width-2-i] == ' ') {
			return width-2-i;
		}
	}
	return -1;
}

// Return unsigned remainder.
Signed!T1 umod(T1, T2)(T1 dividend, T2 divisor)
{
	Signed!T1 signed_modulo = dividend%divisor;
	if (signed_modulo < 0) {
		return divisor+signed_modulo;
	}
	return signed_modulo;
}

// There's a `numerator/denominator` chance it returns true.
bool chance(int numerator, int denominator)
{
	return uniform!"[]"(1, denominator) <= numerator;
}

// A composition of `chance` with a sigmoid function
// (but not the logistic function).
// `x` can be any integer and the probability of returning true
// increases as `x` increases.
// The probability of returning true approaches 1
// as `x` approaches positive infinity;
// approaches 0
// as `x` approaches negative infinity;
// is equal to 0.5 when `x == 0`.
bool sigmoidChance(int x)
{
	return chance(1+x+abs(x), 2+2*abs(x));
}

// A sigmoid function (but not the logistic function).
// The return value approaches `scale` as `x` approaches positive infinity;
// approaches 0 as `x` approaches negative infinity;
// is equal to 0.5 when `x == 0`.
int scaledSigmoid(int scale, int x)
{
	return scale*(1+x+abs(x))/(2+2*abs(x));
}

// Note that if `max-min` is even, then the distribution won't be
// symmetrical.
/*int semibellRandom(int min, int max, int order, Random rng)
{
}*/

// HACK!
string arrayFormat(string fmt, string[] args)
{
	if (args.length == 0) {
		return fmt;
	} else if (args.length == 1) {
		debug writeln(args[0]);
		return format(fmt, args[0]);
	} else if (args.length == 2) {
		debug writeln(fmt, " ", args[0], " ", args[1]);
		return format(fmt, args[0], args[1]);
	} else if (args.length == 3) {
		debug writeln(args[0], " ", args[1], " ", args[2]);
		return format(fmt, args[0], args[1], args[2]);
	} else if (args.length == 4) {
		debug writeln(args[0], " ", args[1], " ", args[2], " ", args[3]);
		return format(fmt, args[0], args[1], args[2], args[3]);
	} else if (args.length == 5) {
		debug writeln(args[0], " ", args[1], " ", args[2], " ", args[3],
			" ", args[4]);
		return format(fmt, args[0], args[1], args[2], args[3], args[4]);
	}
	assert(false);
}
