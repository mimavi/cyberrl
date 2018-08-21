import util;
import ser;
import term;

class Item
{
	mixin Serializable;

	@property abstract Symbol symbol();
	@property abstract string name();
	@property bool is_hit() { return false; }
	@property int blunt_hit_damage() { return 0; }
	@property int sharp_hit_damage() { return 0; }

	this() {}
	this(Serializer serializer) { this(); }
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
	@property override bool is_hit() { return true; }
	@property override int blunt_hit_damage() { return 3; }
	@property override int sharp_hit_damage() { return 10; } 

	this() {}
	this(Serializer serializer) { this(); }
	/*this(Serializer serializer)
	{
		load(serializer);
	}*/
}
