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
		//*/
		//*
		fov_scan(src_x+11, src_y+11, 1, 1, 1, 11, true);
		fov_scan(src_x+11, src_y+11, 1, -1, 1, 11, true);
		fov_scan(src_x+11, src_y+11, -1, 1, 1, 11, true);
		fov_scan(src_x+11, src_y+11, -1, -1, 1, 11, true);
		fov_scan(src_x+11, src_y+11, 1, 1, 1, 11, false);
		fov_scan(src_x+11, src_y+11, 1, -1, 1, 11, false);
		fov_scan(src_x+11, src_y+11, -1, 1, 1, 11, false);
		fov_scan(src_x+11, src_y+11, -1, -1, 1, 11, false);
		get_tile(src_x+11, src_y+11).draw(dest_x+11, dest_y+11);
		//*/
	}

	void fov_scan(int center_x, int center_y, int dir_c, int dir_r,
		int row, int range, bool vert,
		float start_slope = 1, float end_slope = 0)
	{
		if (row > range) return;
		if (end_slope > start_slope) return;

		bool blocking = false;
		for (int cell = cast(int)ceil((row+0.5)*start_slope-0.5);
			cell > ((row-0.5)*end_slope-0.5); cell--)
		{
			Tile tile;
			if (vert) {
				tile = get_tile(center_x+cell*dir_c, center_y+row*dir_r);
				tile.draw(11+cell*dir_c, 11+row*dir_r);
			} else {
				tile = get_tile(center_x+row*dir_r, center_y+cell*dir_c);
				tile.draw(11+row*dir_r, 11+cell*dir_c);
			}

			if (!blocking && tile.is_blocking) {
				blocking = true;
				fov_scan(center_x, center_y, dir_c, dir_r, row+1, range, vert,
					start_slope, (cell+0.5)/(row-0.5));
			} else if (blocking && !tile.is_blocking) {
				blocking = false;
				start_slope = (cell+0.5)/(row+0.5);
			}
		}
		if (!blocking) {
			fov_scan(center_x, center_y, dir_c, dir_r, row+1, range, vert,
				start_slope, end_slope);
		}
	}
}
