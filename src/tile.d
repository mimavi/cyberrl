import util;
import serializer;
import term;
import actor;
import item;
import std.container;

class Tile
{
	mixin Serializable;
	@noser Actor actor;
	Array!Item items;
	@property abstract Symbol symbol();
	@property abstract bool is_blocking();

	this()
	{
		items = Array!Item();
	}
	this(Serializer) { this(); }
	void beforesave(Serializer serializer) {}
	void beforeload(Serializer serializer) {}
	void aftersave(Serializer serializer) {}
	void afterload(Serializer serializer) {}

	void draw(int x, int y) {
		if (actor is null) {
			if (items.empty) {
				term.setSymbol(x, y, symbol);
			} else {
				items.front.draw(x, y);
			}
		} else {
			actor.draw(x, y);
		}
	}
}

class FloorTile : Tile
{
	mixin InheritedSerializable;
	@property override Symbol symbol()
	{
		return Symbol('.', Color.white, Color.black, false);
	}
	@property override bool is_blocking() { return false; }
	this() { super(); }
	this(Serializer serializer) { super(serializer); }
}

class WallTile : Tile
{
	mixin InheritedSerializable;
	@property override Symbol symbol()
		{ return Symbol('#', Color.white, Color.black, false); }
	@property override bool is_blocking() { return true; }
	this() { super(); }
	this(Serializer serializer) { super(serializer); }
}

class MarkerFloorTile : FloorTile
{
	mixin InheritedSerializable;
	Symbol _symbol;
	@property override Symbol symbol() { return _symbol; }
	this(Color color) { super(); _symbol = Symbol('.', color, true); }
	this(Serializer serializer) { super(serializer); }
}
