import util;
import serializer;
import term;

class Item
{
	mixin Serializable;
	@property abstract Symbol symbol();
	@property abstract string name();

	this() {}
	void beforesave(Serializer serializer) {}
	void beforeload(Serializer serializer) {}
	void aftersave(Serializer serializer) {}
	void afterload(Serializer serializer) {}

	final void draw(int x, int y)
	{
		term.setSymbol(x, y, symbol);
	}
}

class LightkatanaItem : Item
{
	mixin InheritedSerializable;
	@property override Symbol symbol()
		{ return Symbol('/', Color.magenta, true); }
	@property override string name() { return "lightkatana"; }

	this() {}
	this(Serializer serializer) { this(); }
	/*this(Serializer serializer)
	{
		load(serializer);
	}*/
}
