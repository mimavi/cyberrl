import util;
import term;
import actor;
import std.container;
import std.math;

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
		term.clear();
		/*
		foreach (y; 0..height) {
			foreach (x; 0..width) {
				get_tile(src_x+x, src_y+y).draw(dest_x+x, dest_y+y);
				//term.setSymbol(dest_x+x, dest_y+y,
					//get_tile(src_x+x, src_y+y).symbol);
			}
		}
		/*/
		//*
		void draw_callback(int tile_x, int tile_y, Tile tile)
		{
			tile.draw(tile_x-src_x+dest_x, tile_y-src_y+dest_x);
		}

		fov(src_x+width/2, src_y+height/2, 11, &draw_callback);
		//*/
	}

	void fov(int center_x, int center_y, int range,
		void delegate(int, int, Tile) callback)
	{
		fov_scan(center_x, center_y, 1, 1, 1, range, true, callback);
		fov_scan(center_x, center_y, 1, -1, 1, range, true, callback);
		fov_scan(center_x, center_y, -1, 1, 1, range, true, callback);
		fov_scan(center_x, center_y, -1, -1, 1, range, true, callback);
		fov_scan(center_x, center_y, 1, 1, 1, range, false, callback);
		fov_scan(center_x, center_y, 1, -1, 1, range, false, callback);
		fov_scan(center_x, center_y, -1, 1, 1, range, false, callback);
		fov_scan(center_x, center_y, -1, -1, 1, range, false, callback);

		callback(center_x, center_y, get_tile(center_x, center_y));
	}

	void fov_scan(int center_x, int center_y, int dir_c, int dir_r,
		int row, int range, bool vert, void delegate(int, int, Tile) callback,
		float start_slope = 1, float end_slope = 0)
	{
		if (row > range) return;
		if (end_slope > start_slope) return;

		bool blocking = false;
		for (int cell = cast(int)ceil((row+0.5)*start_slope-0.5);
			cell > ((row-0.5)*end_slope-0.5); cell--)
		{
			int tile_x = vert ? center_x+cell*dir_c : center_x+row*dir_r;
			int tile_y = vert ? center_y+cell*dir_r : center_y+row*dir_c;
			Tile tile = get_tile(tile_x, tile_y);

			callback(tile_x, tile_y, tile);

			if (!blocking && tile.is_blocking) {
				blocking = true;
				fov_scan(center_x, center_y, dir_c, dir_r, row+1, range, vert,
					callback, start_slope, (cell+0.5)/(row-0.5));
			} else if (blocking && !tile.is_blocking) {
				blocking = false;
				start_slope = (cell+0.5)/(row+0.5);
			}
		}
		if (!blocking) {
			fov_scan(center_x, center_y, dir_c, dir_r, row+1, range, vert,
				callback, start_slope, end_slope);
		}
	}
}
