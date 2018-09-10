// Prevent aborting the executable if a cycle is detected.
// Cycles are not harmful in our case,
// since static constructors don't interact with each other.
extern(C) __gshared string[] rt_options = ["oncycle=ignore"];

//import std.range.primitives;
import std.container;
import std.array;
import std.json;
import std.meta;
import std.traits;
import std.stdio;
import term;
enum noser;

mixin template Serializable()
{
	import std.traits;
	import util;
	//immutable bool is_ser = true;
	enum is_ser = true;
	@noser static typeof(this) function(Serializer)[string] submakes;
	@property string type() { return typeof(this).stringof; }

	static this() // XXX.
	{
		static if (is(typeof(this) == class)) {
			static if (!isAbstractClass!(typeof(this))) {
				submakes[typeof(this).stringof] =
					function typeof(this)(Serializer serializer) {
						return new typeof(this)(serializer);
					};
			}
		} else static if (is(typeof(this) == struct)) {
			submakes[typeof(this).stringof] =
				function typeof(this)(Serializer serializer) {
					return typeof(this)(serializer);
				};
		}
	}

	static typeof(this) make(Serializer serializer)
	{
		//import std.stdio; // XXX.
		/*if (*serializer.stack[$-1]).isNull) {
			return null;
		}*/
		string type = serializer.load!(string, string)("type");
		/*static if (is(typeof(this) == class)) {
			if (type is null) {
				
			}
		} else static if (!isAbstractClass!(typeof(this))) {
			if (type is null) {
				return new typeof(this)(serializer);
			}
		}*/
		if (type is null) {
			static if (is(typeof(this) == class)
			&& !isAbstractClass!(typeof(this))) {
				return new typeof(this)(serializer);
			} else static if (is(typeof(this) == struct)) {

			} else {
				assert(false);
			}
		}
		return submakes[type](serializer);
	}

	void save(Serializer serializer)
	{
		beforesave(serializer);
		serializer.save(type, "type");
		foreach (e; __traits(allMembers, typeof(this))) {
			static if (e != "Monitor"
			&& e != "opUnary"
			&& e != "opBinary"
			&& !hasUDA!(__traits(getMember, typeof(this), e), noser)
			&& isMutable!(typeof(__traits(getMember, this, e)))
			&& !isSomeFunction!(__traits(getMember, typeof(this), e))
			&& hasAddress!(__traits(getMember, this, e))) {
				serializer.save(__traits(getMember, this, e), e);
			}
		}
		aftersave(serializer);
	}

	void load(Serializer serializer)
	{
		beforeload(serializer);
		foreach (e; __traits(allMembers, typeof(this))) {
			static if (e != "Monitor"
			&& e != "opUnary"
			&& e != "opBinary"
			&& !hasUDA!(__traits(getMember, typeof(this), e), noser)
			&& isMutable!(typeof(__traits(getMember, this, e)))
			&& !isSomeFunction!(__traits(getMember, typeof(this), e))
			&& hasAddress!(__traits(getMember, this, e))) {
				alias MemberType = typeof(__traits(getMember, this, e));
				__traits(getMember, this, e)
					= serializer.load!(MemberType)(e);
			}
		}
		afterload(serializer);
	}
}

mixin template InheritedSerializable()
{
	import std.traits;
	@property override string type() { return typeof(this).stringof; }
	static this()
	{
		/*submakes[typeof(this).stringof] =
			function typeof(this)(Serializer serializer) {
				return new typeof(this)(serializer);
			};*/
		static if (!isAbstractClass!(typeof(this))) {
			submakes[typeof(this).stringof] =
				function typeof(this)(Serializer serializer) {
					return new typeof(this)(serializer);
				};
		}
	}
}

mixin template SimplySerialized()
{
	void beforesave(Serializer serializer) {}
	void beforeload(Serializer serializer) {}
	void aftersave(Serializer serializer) {}
	void afterload(Serializer serializer) {}
}

class Serializer
{
	private JSONValue*[] stack;
	private JSONValue root;
	@property str() { return root.toPrettyString(); }
	@property str(string str) { root = parseJSON(str); }

	this()
	{
		root = JSONValue((JSONValue[string]).init);
		stack.length = 1;
		stack[$-1] = &root;
	}

	void save(ValType, KeyType)(ValType val, KeyType key) {
		// TODO: Optimize.
		// Increasing dynamic array length is expensive.
		static if (__traits(hasMember, ValType, "is_ser")) {
			saveSerializable(val, key);
			return;
		} else static if (is(ValType == Array!ElementType, ElementType)) {
			saveArrayContainer!(ValType, KeyType, ElementType)(val, key);
			return;
		} else static if (is(ValType == DList!ElementType, ElementType)) {
			saveDListContainer!(ValType, KeyType, ElementType)(val, key);
			return;
		} else static if (is(ValType == SList!ElementType, ElementType)) {
			saveSListContainer!(ValType, KeyType, ElementType)(val, key);
			return;
		} else static if (isSomeString!ValType) {
			// This block must be above `ValType == ElementType[]...` block.
			saveString(val, key);
			return;
		} else static if (isStaticArray!ValType) {
			alias ElementType = typeof(ValType.init.front.init);
			saveStaticArray!(ValType, KeyType, ElementType)(val, key);
		// Dynamic array.
		} else static if (is(ValType == ElementType[], ElementType)) {
			saveDynamicArray!(ValType, KeyType, ElementType)(val, key);
			return;
		} else static if (isNumeric!ValType || isSomeChar!ValType) {
			saveNumeric(val, key);
			return;
		} else static if (isBoolean!ValType) {
			saveBoolean(val, key);
			return;
		} else {
			pragma(msg,
				"Error: `save` does not handle "~ValType.stringof~".");
			static assert(false);
		}
	}

	ValType load(ValType, KeyType)(KeyType key)
	{
		static if (__traits(hasMember, ValType, "is_ser")) {
			return loadSerializable!(ValType)(key);
		} else static if (is(ValType == Array!ElementType, ElementType)) {
			return loadArrayContainer!(ValType, KeyType, ElementType)(key);
		} else static if (is(ValType == DList!ElementType, ElementType)) {
			return loadDListContainer!(ValType, KeyType, ElementType)(key);
		} else static if (is(ValType == SList!ElementType, ElementType)) {
			return loadSListContainer!(ValType, KeyType, ElementType)(key);
		} else static if (isSomeString!ValType) {
			return loadString!(ValType)(key);
		} else static if (isStaticArray!ValType) {
			alias ElementType = typeof(ValType.init.front.init);
			return loadStaticArray!(ValType, KeyType, ElementType)(key);
		} else static if (is(ValType == ElementType[], ElementType)) {
			return loadDynamicArray!(ValType, KeyType, ElementType)(key);
		} else static if (isNumeric!ValType || isSomeChar!ValType) {
			return loadNumeric!(ValType)(key);
		} else static if (isBoolean!ValType) {
			return loadBoolean(key);
		} else {
			pragma(msg,
				"Error: `load` does not handle "~ValType.stringof~".");
			static assert(false);
		}
	}

	void saveSerializable(ValType, KeyType)(ValType val, KeyType key)
	{
		static if (is(ValType == class)) {
			if (val is null)
				return;
		}
		++stack.length;
		//*(stack[$-1]) = JSONValue((JSONValue[string]).init);
		(*stack[$-2])[key] = JSONValue((JSONValue[string]).init);
		stack[$-1] = &((*stack[$-2])[key]);
		val.save(this);
		--stack.length;
	}

	ValType loadSerializable(ValType, KeyType)(KeyType key)
	{
		static if (isSomeString!KeyType) {
			if ((key in (*stack[$-1])) is null) {
				static if (is(ValType == class)) {
					return null;
				} else static if (is(ValType == struct)) {
					return ValType.make(this);
				} else {
					static assert(false);
				}
			}
		}
		static if (isIntegral!KeyType) {
			if ((*stack[$-1])[key].isNull) {
				static if (is(ValType == class)) {
					return null;
				} else static if (is(ValType == struct)) {
					return ValType.make(this);
				} else {
					static assert(false);
				}
			}
		}
		++stack.length;
		//(*stack[$-1])[key] = ValType.make(this);
		stack[$-1] = &((*stack[$-2])[key]);
		// XXX: This cast may cause problems.
		ValType val = cast(ValType)ValType.make(this);

		val.load(this);
		--stack.length;
		return val;
	}

	void saveArrayContainer(ValType, KeyType, ElementType)
		(ValType val, KeyType key)
	{
		(*stack[$-1])[key] = JSONValue((JSONValue[]).init);
		(*stack[$-1])[key].array.length = val.length;
		auto length = val.length;
		++stack.length;
		stack[$-1] = &((*stack[$-2])[key]);
		foreach (v; val[]) {
			save(v, length-val.length);
		}
		--stack.length;
	}

	ValType loadArrayContainer(ValType, KeyType, ElementType)
		(KeyType key)
	{
		++stack.length;
		stack[$-1] = &((*stack[$-2])[key]);
		ValType val = Array!ElementType();
		val.length = (*stack[$-1]).array.length;
		foreach (int i, v; (*stack[$-1]).array) {
			val[i] = load!(ElementType)(i);
		}
		--stack.length;
		return val;
	}

	void saveDListContainer(ValType, KeyType, ElementType)
		(ValType val, KeyType key)
	{
		(*stack[$-1])[key] = JSONValue((JSONValue[]).init);
		//(*stack[$-1])[key].array.length = val.length;
		//auto length = val.length;
		++stack.length;
		stack[$-1] = &((*stack[$-2])[key]);
		int i = 0;
		foreach (v; val[]) {
			++(*stack[$-1]).array.length;
			save(v, i);
			++i;
		}
		--stack.length;
	}

	ValType loadDListContainer(ValType, KeyType, ElementType)
		(KeyType key)
	{
		++stack.length;
		stack[$-1] = &((*stack[$-2])[key]);
		ValType val = ValType();
		foreach (int i, v; (*stack[$-1]).array) {
			// IDK why the documentation states this function is O(log(n)).
			val.insertBack(load!(ElementType)(i));
			//val[i] = load!(ElementType)(i);
		}
		--stack.length;
		return val;
	}

	alias saveSListContainer = saveDListContainer;
	alias loadSListContainer = loadDListContainer;

	void saveStaticArray(ValType, KeyType, ElementType)
		(ValType val, KeyType key)
	{
		(*stack[$-1])[key] = JSONValue((JSONValue[]).init);
		(*stack[$-1])[key].array.length = val.length;
		++stack.length;
		stack[$-1] = &((*stack[$-2])[key]);
		foreach (int i, v; val) {
			save(v, i);
		}
		--stack.length;
	}

	ValType loadStaticArray(ValType, KeyType, ElementType)(KeyType key)
	{
		static if (isSomeString!ValType) {
			return (*(stack[$-1]))[key].str;
		} else {
			++stack.length;
			stack[$-1] = &((*stack[$-2])[key]);
			ValType val;
			foreach (int i, e; (*stack[$-1]).array) {
				val[i] = load!(ElementType)(i);
			}
			--stack.length;
			return val;
		}
	}

	/*void saveDynamicArray(ValType, KeyType, ElementType)
		(ValType val, KeyType key)
	{
		(*stack[$-1])[key] = JSONValue((JSONValue[]).init);
		(*stack[$-1])[key].array.length = val.length;
		++stack.length;
		stack[$-1] = &((*stack[$-2])[key]);
		foreach (int i, v; val) {
			save(v, i);
		}
		--stack.length;
	}*/
	alias saveDynamicArray = saveStaticArray;

	ValType loadDynamicArray(ValType, KeyType, ElementType)(KeyType key)
	{
		static if (isSomeString!ValType) {
			return (*(stack[$-1]))[key].str;
		} else {
			++stack.length;
			stack[$-1] = &((*stack[$-2])[key]);
			//ValType val = ValType.make(this);
			ValType val;
			val.length = (*stack[$-1]).array.length;
			foreach (int i, v; (*stack[$-1]).array) {
				val[i] = load!(ElementType)(i);
			}
			--stack.length;
			return val;
		}
	}

	void saveString(ValType, KeyType)(ValType val, KeyType key)
	{
		(*(stack[$-1]))[key] = val;
	}

	ValType loadString(ValType, KeyType)(KeyType key)
	{
		return cast(ValType)(*(stack[$-1]))[key].str;
	}

	alias saveNumeric = saveString;
	//void saveNumeric(ValType, KeyType)(ValType val, KeyType key)
	//{
		/*static if (isIntegral!ValType) {
			static if (isUnsigned!ValType) {
				(*(stack[$-1]))[key].uinteger = val;
			} else static if (
		} else static if (isFloatingPoint!ValType) {
		}*/
	//}

	ValType loadNumeric(ValType, KeyType)(KeyType key)
	{
		/*static if (isIntegral!ValType) {
			static if (isUnsigned!ValType) {
				return cast(ValType)((*(stack[$-1]))[key].uinteger);
			} else static if (isSigned!ValType) {
				return cast(ValType)((*(stack[$-1]))[key].integer);
			}
		} else static if (isFloatingPoint!ValType) {
			return cast(ValType)((*stack[$-1]))[key].floating;
		}*/
		if ((*(stack[$-1]))[key].type == JSON_TYPE.UINTEGER) {
			return cast(ValType)(*(stack[$-1]))[key].uinteger;
		} else if ((*(stack[$-1]))[key].type == JSON_TYPE.INTEGER) {
			return cast(ValType)(*(stack[$-1]))[key].integer;
		} else if ((*(stack[$-1]))[key].type == JSON_TYPE.FLOAT) {
			return cast(ValType)(*(stack[$-1]))[key].floating;
		} else {
			assert(false);
		}
	}

	alias saveBoolean = saveString;
	bool loadBoolean(KeyType)(KeyType key)
	{
		if ((*stack[$-1])[key].type == JSON_TYPE.TRUE) {
			return true;
		}
		return false;
	}

	/*void saveNumeric(ValType, KeyType)(ValType val, KeyType key)
	{
		(*(stack[$-1]))[key] = val;
	}*/
}
