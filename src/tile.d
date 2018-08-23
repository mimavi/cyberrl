import util;
import ser;
import term;
import actor;
import item;
import std.container;

// XXX: Perhaps place it in `map.d`?
bool debug_is_all_visible = false;

class Tile
{
	mixin Serializable;
	@noser Actor actor;
	Array!Item items;

	private Symbol last_visible_symbol = Symbol(' ');
	private bool _is_visible = false;

	@property abstract bool is_walkable();
	@property abstract bool is_transparent();
	@property protected abstract Symbol symbol();
	@property bool is_default() { return false; }
	@property bool is_static() { return true; }

	@property void is_visible(bool val)
	{
		_is_visible = val;
		if (val) {
			last_visible_symbol = visible_symbol;
		}
	}

	@property bool is_visible()
	{
		if (debug_is_all_visible) {
			return true;
		}
		return _is_visible;
	}

	@property Symbol visible_symbol()
	{
		if (!is_visible) {
			Symbol result = last_visible_symbol;
			result.color = Color.black;
			result.bg_color = Color.black;
			result.is_bright = true;
			return result;
		} else if (actor is null) {
			if (items.empty) {
				//term.setSymbol(x, y, symbol);
				return symbol;
			} else {
				//items.front.draw(x, y);
				return items.front.symbol;
			}
		} else {
			//actor.draw(x, y);
			return actor.symbol;
		}
	}

	this()
	{
		items = Array!Item();
	}
	this(Serializer) { this(); }
	void beforesave(Serializer serializer) {}
	void beforeload(Serializer serializer) {}
	void aftersave(Serializer serializer) {}
	void afterload(Serializer serializer) {}

	final void draw(int x, int y) {
		/*if (!is_visible) {
			term.setSymbol(x, y, last_visible_symbol);
		} else if (actor is null) {
			if (items.empty) {
				term.setSymbol(x, y, symbol);
			} else {
				items.front.draw(x, y);
			}
		} else {
			actor.draw(x, y);
		}*/
		term.setSymbol(x, y, visible_symbol);
	}
}

class FloorTile : Tile
{
	mixin InheritedSerializable;
	@property override Symbol symbol() { return Symbol('.', Color.white); }
	@property override bool is_walkable() { return true; }
	@property override bool is_transparent() { return true; }
	this() { super(); }
	this(Serializer serializer) { super(serializer); }
}

class WallTile : Tile
{
	mixin InheritedSerializable;
	@property override Symbol symbol() { return Symbol('#', Color.white); }
	@property override bool is_walkable() { return false; }
	@property override bool is_transparent() { return false; }
	this() { super(); }
	this(Serializer serializer) { super(serializer); }
}

class DefaultWallTile : WallTile
{
	mixin InheritedSerializable;
	@property override bool is_default() { return true; }
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

class HDoorTile : Tile
{
	mixin InheritedSerializable;
	@property override Symbol symbol() { return Symbol('+', Color.yellow); }
	@property override bool is_static() { return false; }
	@property override bool is_walkable() { return /*false;*/ true; }
	@property override bool is_transparent() { return false; }
	this() { super(); }
	this(Serializer serializer) { super(serializer); }
}

class VDoorTile : Tile
{
	mixin InheritedSerializable;
	@property override Symbol symbol() { return Symbol('+', Color.yellow); }
	@property override bool is_static() { return false; }
	@property override bool is_walkable() { return /*false;*/ true; }
	@property override bool is_transparent() { return false; }
	this() { super(); }
	this(Serializer serializer) { super(serializer); }
}
