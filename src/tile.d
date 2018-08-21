import util;
import ser;
import term;
import actor;
import item;
import std.container;

class Tile
{
	mixin Serializable;
	@noser Actor actor;
	Array!Item items;
	private Symbol last_visible_symbol = Symbol(' ');
	private bool _is_visible = false;

	@property abstract bool is_blocking();
	@property protected abstract Symbol symbol();

	@property void is_visible(bool val)
	{
		_is_visible = val;
		if (val) {
			last_visible_symbol = visible_symbol;
		}
	}
	@property bool is_visible() { return _is_visible; }

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
	@property override Symbol symbol()
		{ return Symbol('.', Color.white, Color.black, false); }
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
