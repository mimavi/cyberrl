import std.container;
import std.traits;
import std.array;
import std.stdio;
import std.json;
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

int[255] chr_to_index = [
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

char[chr_to_index.length] index_to_chr = [
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

class SaveManager
{
	private JSONValue tree;
	private Array!JSONValue nodes;

	this()
	{
		nodes = Array!JSONValue();
		nodes.insertBack(JSONValue((JSONValue[string]).init));
	}

	void save(T)(T var/*, File file*/)
	{
		/*foreach (k; __traits(allMembers, T)) {
			writeln(k);
			static if (k != "Monitor") {
				alias T2 = typeof(__traits(getMember, var, k));
				static if (isScalarType!T2) {
					writeln("scalar");
					auto v = __traits(getMember, var, k);
					saveScalar!T2(v);
				}
			}
		}*/
		insert(var);
		writeln(nodes.front.toString);
	}

	T load(T)(File file)
	{
	}

	private void insert(T)(T var)
	{
		static if (is(T == Array!S, S)
		|| is(T == SList!S, S)
		|| is(T == DList!S, S)) {
			int i = 0;
			foreach (v; var[]) {
				writeln("a: ", i, " ", v);
				++i;
			}
		} else static if (isAggregateType!T) {
			writeln("x");
			static if (is(T == class)) {
				if (var is null) {
					return;
				}
			}
			insertAggregate(var);
			//auto names2 = FieldNameTuple!(BaseTypeTuple!T);
			//writeln("yy ", [names2]);
		}
	}

	void insertAggregate(T)(T var)
	{
		alias names = FieldNameTuple!T;
		writeln("y: ", [names], " ", T.stringof);
		foreach (k, v; var.tupleof) {
			writeln("b: ", k, " ", names[k], " "/*, v*/);
			/*foreach (k, S; __traits(getAttributes, v)) {
				writeln("j: ", k, " ", S.stringof);
			}*/
			import game;
			static if (is(T == Game)) {
				pragma(msg, names[k]);
				pragma(msg, hasUDA!(v, "NotSaved"));
			}
			static if (isScalarType!(typeof(v))) {
				writeln("c");
				nodes.back[names[k]] = JSONValue(v);
			} else { 
				writeln("d: ", names[k]);
				nodes.back[names[k]] = JSONValue((JSONValue[string]).init);
				nodes.insertBack(nodes.back[names[k]]);
				insert(v);
				nodes.removeBack();
			}
			
			/*else static if (is(typeof(v) == Array!S, S)
			|| is(typeof(v) == SList!S, S)
			|| is(typeof(v) == DList!S, S)) {
				nodes.back[names[k]] = JSONValue(cast(int[])[]);
				//for (int i = 0; i < v.length; ++i) {
					//nodes.back[names[k]][i] = v[i];
				//}
				int i = 0;
				foreach (u; v[]) {
					//nodes.back[names[k]][i] = u;
					//++i;
				}
			} else static if (isAggregateType!(typeof(v))) {
				writeln("is aggregate");
				nodes.insertBack(JSONValue(names[k]));
				insert(v);
				nodes.removeBack();
			}*/
		}
		foreach (k, S; BaseTypeTuple!T) {
			writeln("q: ", S.stringof);
			//insertAggregate(cast(S)var);
		}
	}
}
