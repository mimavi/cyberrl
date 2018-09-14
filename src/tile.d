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

	@property abstract string name() const;
	@property string displayed_name() const
	{
		return prependIndefiniteArticle(name);
	}
	@property abstract Symbol symbol() /*pure*/ const;

	@property abstract bool is_walkable() /*pure*/ const;
	@property abstract bool is_transparent() /*pure*/ const;
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
				return symbol;
			} else {
				return items.front.symbol;
			}
		} else {
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
		term.setSymbol(x, y, visible_symbol);
	}

	// TODO: Rename to `tryOpen` and `tryClose` respectively.
	// Return false if cannot be opened/closed for some reason
	// i.e. not a door or is jammed.
	bool open() /*pure*/ { return false; }
	bool close() /*pure*/ { return false; }
}
