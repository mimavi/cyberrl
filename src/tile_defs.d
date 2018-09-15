import util;
import ser;
import term;
import tile;

class FloorTile : Tile
{
	mixin InheritedSerializable;
	@property override string name() const { return "floor"; }
	@property override string displayed_name() const { return "the "~name; }
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
	@property override string name() const { return "wall"; }
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
	@property override string name() const { return "door"; }
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
