import util;
import term;
import actor;
import item;
import std.container;

class Tile
{
	Actor actor;
	Array!Item items;
	abstract @property Symbol symbol();
	abstract @property bool is_blocking();

	this()
	{
		items = make!(Array!Item)();
	}

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
	override @property Symbol symbol()
	{
		return Symbol('.', Color.white, Color.black, false);
	}
	override @property bool is_blocking() { return false; }
}

class WallTile : Tile
{
	override @property Symbol symbol()
	{
		return Symbol('#', Color.white, Color.black, false);
	}
	override @property bool is_blocking() { return true; }
}

