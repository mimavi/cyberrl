import util;
import ser;
import term;
import actor;
import item;
import std.container;

// XXX: Perhaps place it in `map.d`?
immutable bool debug_is_all_visible = false;

class Tile
{
	mixin Serializable;
	@noser Actor actor;
	Array!Item items;

	// 0 is none.
	int zone = 0;
	private Symbol last_visible_symbol = Symbol(' ');
	private bool _is_visible = false;

	@property abstract bool is_walkable() /*pure*/ const;
	@property abstract bool is_transparent() /*pure*/ const;
	@property protected abstract Symbol symbol() /*pure*/ const;
	@property bool is_default() /*pure*/ const { return false; }
	@property bool is_static() /*pure*/ const { return true; }

	@property void is_visible(bool val) /*pure*/
	{
		_is_visible = val;
		if (val) {
			last_visible_symbol = visible_symbol;
		}
	}

	@property bool is_visible() /*pure*/ const
	{
		if (debug_is_all_visible) {
			return true;
		}
		return _is_visible;
	}

	@property Symbol visible_symbol() /*pure*/ const
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

	this() /*pure*/
	{
		items = Array!Item();
	}
	this(Serializer) /*pure*/ { this(); }
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

	// Return false if cannot be opened/closed for some reason
	// i.e. not a door or is jammed.
	bool open() /*pure*/ { return false; }
	bool close() /*pure*/ { return false; }
}

class FloorTile : Tile
{
	mixin InheritedSerializable;
	@property override Symbol symbol() const
		{ return Symbol('.', Color.white); }
	@property override bool is_walkable() const { return true; }
	@property override bool is_transparent() const { return true; }
	this() /*pure*/ { super(); }
	this(Serializer serializer) /*pure*/ { super(serializer); }
}

class WallTile : Tile
{
	mixin InheritedSerializable;
	@property override Symbol symbol() const
		{ return Symbol('#', Color.white); }
	@property override bool is_walkable() const { return false; }
	@property override bool is_transparent() const { return false; }
	this() /*pure*/ { super(); }
	this(Serializer serializer) /*pure*/ { super(serializer); }
}

class DefaultWallTile : WallTile
{
	mixin InheritedSerializable;
	@property override bool is_default() const { return true; }
	this() /*pure*/ { super(); }
	this(Serializer serializer) /*pure*/ { super(serializer); }
}

class MarkerFloorTile : FloorTile
{
	mixin InheritedSerializable;
	Symbol _symbol;
	@property override Symbol symbol() const { return _symbol; }
	this(Color color) /*pure*/ { super(); _symbol = Symbol('.', color, true); }
	this(Serializer serializer) /*pure*/ { super(serializer); }
}

class DoorTile : Tile
{
	protected bool is_open = false;
	@property override bool is_static() const { return false; }
	@property override bool is_walkable() const { return is_open; }
	@property override bool is_transparent() const { return is_open; }
	this() /*pure*/ { super(); }
	this(bool is_open) /*pure*/ { this(); this.is_open = is_open; }
	this(Serializer serializer) /*pure*/ { super(serializer); }
	override bool open() /*pure*/
	{
		if (is_open) {
			return false;
		}
		is_open = true;
		return true;
	}
	override bool close() /*pure*/
	{
		if (!is_open) {
			return false;
		}
		is_open = false;
		return true;
	}
}

class HDoorTile : DoorTile
{
	mixin InheritedSerializable;
	@property override Symbol symbol() const /*pure*/
	{
		if (is_open) {
			return Symbol('-', Color.yellow);
		} else {
			return Symbol('+', Color.yellow);
		}
	}
	this() /*pure*/ { super(); }
	this(bool is_open) /*pure*/ { this(); this.is_open = is_open; }
	this(Serializer serializer) /*pure*/ { super(serializer); }
}

class VDoorTile : DoorTile
{
	mixin InheritedSerializable;
	@property override Symbol symbol() const /*pure*/
	{
		if (is_open) {
			return Symbol('|', Color.yellow);
		} else {
			return Symbol('+', Color.yellow);
		}
	}
	this() /*pure*/ { super(); }
	this(bool is_open) /*pure*/ { this(); this.is_open = is_open; }
	this(Serializer serializer) /*pure*/ { super(serializer); }
}
