import util;
import serializer;
import term;
import actor;
import item;
import std.container;

int a = 1;

class Tile
{
	mixin Serializable;
	Actor actor;
	Array!Item items;
	@property abstract Symbol symbol();
	@property abstract bool is_blocking();

	this()
	{
		items = Array!Item();
	}
	this(Serializer) { this(); }

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
	this() { super(); }
	this(Serializer serializer) { super(serializer); }
	@property override Symbol symbol()
	{
		return Symbol('.', Color.white, Color.black, false);
	}
	@property override bool is_blocking() { return false; }
}

class WallTile : Tile
{
	mixin InheritedSerializable;
	this() { super(); }
	this(Serializer serializer) { super(serializer); }
	override @property Symbol symbol()
	{
		return Symbol('#', Color.white, Color.black, false);
	}
	override @property bool is_blocking() { return true; }
}

