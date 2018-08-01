import term;
import util;
import serializer;

class Item
{
	mixin Serializable;
	@property abstract Symbol symbol();
	@property abstract string name();

	this() {}

	void draw(int x, int y)
	{
		term.setSymbol(x, y, symbol);
	}
}

class LightkatanaItem : Item
{
	mixin InheritedSerializable;
	@property override Symbol symbol() { return Symbol('/', Color.cyan); }
	@property override string name() { return "lightkatana"; }

	this() {}
	this(Serializer serializer) { this(); }
	/*this(Serializer serializer)
	{
		load(serializer);
	}*/
}
