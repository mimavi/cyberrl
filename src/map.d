import std.container;
import std.range;
import std.math;
import util;
import serializer;
import term;
import tile;
import actor;
import item;

class Map
{
	mixin Serializable;
	private Tile[] tiles;
	private DList!Actor actors;
	private Tile tmp;
	private int _width, _height;
	@property int width() { return _width; }
	@property int height() { return _height; }

	this(Serializer serializer)
	{
		this(serializer.load!(int)("_width"),
			serializer.load!(int)("_height"));
	}

	this(int width, int height)
	{
		_width = width;
		_height = height;
		tiles.length = width*height;
		foreach (y; 0..height) {
			foreach (x; 0..width) {
				getTile(x, y) = new FloorTile;
			}
		}
		actors = DList!Actor();
	}

	ref Tile getTile(int x, int y)
	{
		if (x < 0 || y < 0 || x >= _width || y >= _width) {
			tmp = new WallTile;
			return tmp;
		}
		return tiles[x+y*_width];
	}

	void addActor(Actor actor, int x, int y)
	{
		actors.insertBack(actor);
		actor.initPos(x, y);
	}

	bool update()
	{
		for (auto range = actors[]; !range.empty; range.popFront()) {
			if (range.front.is_despawned) {
				actors.popFirstOf(range);
			} else {
				if (!range.front.update()) {
					return false;
				}
			}
		}
		return true;
	}

	void draw(int src_x, int src_y, int dest_x, int dest_y,
		int width, int height)
	{
		term.clear();
		/*
		foreach (y; 0..height) {
			foreach (x; 0..width) {
				getTile(src_x+x, src_y+y).draw(dest_x+x, dest_y+y);
				//term.setSymbol(dest_x+x, dest_y+y,
					//getTile(src_x+x, src_y+y).symbol);
			}
		}
		/*/
		//*
		void drawCallback(int tile_x, int tile_y, Tile tile)
		{
			int x = tile_x-src_x+dest_x;
			int y = tile_y-src_y+dest_y;

			if (x >= dest_x && y >= dest_y &&
				x < dest_x+width && y < dest_y+height)
			{
				tile.draw(x, y);
			}
		}

		fov(src_x+width/2, src_y+height/2, 11, &drawCallback);
		//*/
	}

	void fov(int center_x, int center_y, int range,
		void delegate(int, int, Tile) callback)
	{
		fovScan(center_x, center_y, 1, 1, 1, range, true, callback);
		fovScan(center_x, center_y, 1, -1, 1, range, true, callback);
		fovScan(center_x, center_y, -1, 1, 1, range, true, callback);
		fovScan(center_x, center_y, -1, -1, 1, range, true, callback);
		fovScan(center_x, center_y, 1, 1, 1, range, false, callback);
		fovScan(center_x, center_y, 1, -1, 1, range, false, callback);
		fovScan(center_x, center_y, -1, 1, 1, range, false, callback);
		fovScan(center_x, center_y, -1, -1, 1, range, false, callback);

		callback(center_x, center_y, getTile(center_x, center_y));
	}

	void fovScan(int center_x, int center_y, int dir_c, int dir_r,
		int row, int range, bool vert, void delegate(int, int, Tile) callback,
		float start_slope = 1, float end_slope = 0)
	{
		if (row > range) return;
		if (end_slope > start_slope) return;

		bool was_blocking = false;
		for (int cell = cast(int)ceil((row+0.5)*start_slope-0.5);
			cell > ((row-0.5)*end_slope-0.5); cell--)
		{
			int tile_x = vert ? center_x+cell*dir_c : center_x+row*dir_r;
			int tile_y = vert ? center_y+row*dir_r : center_y+cell*dir_c;
			Tile tile = getTile(tile_x, tile_y);

			callback(tile_x, tile_y, tile);

			if (!was_blocking && tile.is_blocking) {
				fovScan(center_x, center_y, dir_c, dir_r, row+1, range, vert,
					callback, start_slope, (cell+0.5)/(row-0.5));
				was_blocking = true;
			} else if (was_blocking && !tile.is_blocking) {
				start_slope = (cell+0.5)/(row+0.5);
				was_blocking = false;
			}
		}
		if (!was_blocking) {
			fovScan(center_x, center_y, dir_c, dir_r, row+1, range, vert,
				callback, start_slope, end_slope);
		}
	}
}
