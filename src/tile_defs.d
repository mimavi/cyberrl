import util;
import ser;
import term;
import tile;

class FloorTile : Tile
{
	mixin (inherited_serializable);
	@property override string name() const pure { return "floor"; }
	@property override string displayed_name() const pure 
		{ return "the "~name; }
	@property override Symbol symbol() const pure
		{ return Symbol('.', Color.white); }
	@property override bool is_walkable() const pure { return true; }
	@property override bool is_transparent() const pure { return true; }
	this() pure { super(); }
	this(Serializer serializer) pure { super(serializer); }
}

class WallTile : Tile
{
	mixin (inherited_serializable);
	@property override string name() const pure { return "wall"; }
	@property override Symbol symbol() const pure
		{ return Symbol('#', Color.white); }
	@property override bool is_walkable() const pure { return false; }
	@property override bool is_transparent() const pure { return false; }
	this() pure { super(); }
	this(Serializer serializer) pure { super(serializer); }
}

class DefaultWallTile : WallTile
{
	mixin (inherited_serializable);
	@property override bool is_default() const pure { return true; }
	this() pure { super(); }
	this(Serializer serializer) pure { super(serializer); }
}

class MarkerFloorTile : FloorTile
{
	mixin (inherited_serializable);
	Symbol _symbol;
	@property override Symbol symbol() const pure { return _symbol; }
	this(Color color) pure { super(); _symbol = Symbol('.', color, true); }
	this(Serializer serializer) pure { super(serializer); }
}

class DoorTile : Tile
{
	mixin (inherited_serializable);
	protected bool is_open = false;
	@property override string name() const { return "door"; }
	@property override bool is_static() const { return false; }
	@property override bool is_walkable() const { return is_open; }
	@property override bool is_transparent() const { return is_open; }
	this() pure { super(); }
	this(bool is_open) pure { this(); this.is_open = is_open; }
	this(Serializer serializer) pure { super(serializer); }
	override bool open() pure
	{
		if (is_open) {
			return false;
		}
		is_open = true;
		return true;
	}
	override bool close() pure
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
	mixin (inherited_serializable);
	@property override Symbol symbol() const pure
	{
		if (is_open) {
			return Symbol('-', Color.yellow);
		} else {
			return Symbol('+', Color.yellow);
		}
	}
	this() pure { super(); }
	this(bool is_open) pure { this(); this.is_open = is_open; }
	this(Serializer serializer) pure { super(serializer); }
}

class VDoorTile : DoorTile
{
	mixin (inherited_serializable);
	@property override Symbol symbol() const pure
	{
		if (is_open) {
			return Symbol('|', Color.yellow);
		} else {
			return Symbol('+', Color.yellow);
		}
	}
	this() pure { super(); }
	this(bool is_open) pure { this(); this.is_open = is_open; }
	this(Serializer serializer) pure { super(serializer); }
}
