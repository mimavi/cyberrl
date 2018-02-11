import util;
import term;
import actor;
import std.container;

class Tile
{
	Actor actor;
	abstract @property Symbol symbol();
	abstract @property bool is_blocking();

	void draw(int x, int y) {
		if(actor is null) {
			term.setSymbol(x, y, symbol);
		}
		else {
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

class Map
{
	SList!Actor actors;
	private int _width, _height;
	private Tile[] _tiles;
	private Tile tmp;

	this(int width, int height)
	{
		_width = width;
		_height = height;
		_tiles.length = width*height;
		foreach (y; 0..height) {
			foreach (x; 0..width) {
				get_tile(x, y) = new FloorTile;
			}
		}
		actors = make!(SList!Actor)();
	}

	@property int width() { return _width; }
	@property int height() { return _height; }
	ref Tile get_tile(int x, int y)
	{
		if(x < 0 || y < 0 || x >= _width || y >= _width) {
			tmp = new WallTile;
			return tmp;
		}
		return _tiles[x+y*_width];
	}

	void update()
	{
		foreach (actor; actors[]) {
			actor.update();
		}
	}

	void draw(int src_x, int src_y, int dest_x, int dest_y,
		int width, int height)
	{
		foreach (y; 0..height) {
			foreach (x; 0..width) {
				get_tile(src_x+x, src_y+y).draw(dest_x+x, dest_y+y);
				//term.setSymbol(dest_x+x, dest_y+y,
					//get_tile(src_x+x, src_y+y).symbol);
			}
		}
	}
}
