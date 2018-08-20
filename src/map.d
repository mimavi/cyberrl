import iteration = std.algorithm.iteration;
import std.functional;
import std.container;
import std.random;
import std.range;
import std.math;
import util;
import serializer;
import term;
import tile;
import actor;
import item;

// TODO: Rename `blocking` to `!passable` in movement context.
// It's more clear.

class Map
{
	mixin Serializable;
	private Tile[] tiles;
	private DList!Actor actors;
	@noser private Tile tmp;
	private int _width, _height;
	@property int width() { return _width; }
	@property int height() { return _height; }

	this(Serializer serializer)
	{
		this(serializer.load!int("_width"),
			serializer.load!int("_height"));
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

	void beforesave(Serializer serializer) {}
	void beforeload(Serializer serializer) {}
	void aftersave(Serializer serializer) {}
	void afterload(Serializer serializer)
	{
		foreach (e; actors[]) {
			e.map = this;
			getTile(e.x, e.y).actor = e;
		}
	}

	// XXX: Why `ref`?
	ref Tile getTile(int x, int y)
	{
		if (x < 0 || y < 0 || x >= _width || y >= _width) {
			tmp = new WallTile;
			return tmp;
		}
		return tiles[x+y*_width];
	}

	void spawn(Actor actor, int x, int y)
	{
		actor.map = this;
		actors.insertBack(actor);
		actor.initPos(x, y);
	}

	void despawn(Actor actor)
	{
		actor.is_despawned = true;
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
		int row, int range, bool vert,
		void delegate(int, int, Tile) callback,
		float start_slope = 1, float end_slope = 0)
	{
		if (row > range) return;
		if (end_slope > start_slope) return;

		bool was_blocking = false;
		for (int cell = cast(int)ceil((row+0.5)*start_slope-0.5);
		cell > ((row-0.5)*end_slope-0.5); cell--) {
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

	// TODO: Take movement speed dependency on tile type into consideration.
	Point[] findPath(int source_x, int source_y, int target_x, int target_y,
		bool delegate(int, int) get_is_passable =
			toDelegate(&findPathGetIsPassable),
		Point[8] delegate(int, int) get_next_coords =
			toDelegate(&findPathGetNextCoords))
	{
		import std.conv; import std.stdio; writeln("source: "~to!string(source_x)~" "~to!string(source_y));
		Point[] stack = [Point(source_x, source_y)];
		int cur_x = source_x, cur_y = source_y;
		//bool[tiles.length] was_visited; // All false by default.
		int[] steps; // All 0 by default.
		Point[] links;
		steps.length = tiles.length;
		links.length = tiles.length;
		
		//foreach (e; stack) {
		for (int i = 0; i < stack.length; ++i) {
			auto e = stack[i];
			foreach (ee; findPathGetNextCoords(e.x, e.y)) {
				// Target tile need not be passable
				// to be reachable in this routine.
				if (ee.x == target_x && ee.y == target_y) {
					Point[] result = [Point(source_x, source_y)];
					result.length = steps[e.x+e.y*width]+1;
					result[$-1] = Point(target_x, target_y);

					for ({Point cur = e; int ii = 0;}
					cur.x != source_x || cur.y != source_y;
					cur = links[cur.x+cur.y*width], ++ii) {
						result[$-2-ii] = cur;
					}
					import std.stdio; writeln(result); // XXX.
					return result;
				}

				if (findPathGetIsPassable(ee.x, ee.y)
				&& steps[ee.x+ee.y*width] == 0) {
					links[ee.x+ee.y*width] = Point(e.x, e.y);
					steps[ee.x+ee.y*width] = steps[e.x+e.y*width]+1;
					++stack.length;
					stack[$-1] = ee;
				}
			}
		}
		return [];
	}

	bool findPathGetIsPassable(int x, int y)
	{
		return !getTile(x, y).is_blocking;
	}

	Point[8] findPathGetNextCoords(int x, int y)
	{
		auto diagonal_dirs =
			[Dir.up_right, Dir.up_left, Dir.down_left, Dir.down_right];
		auto orthogonal_dirs = [Dir.right, Dir.up, Dir.left, Dir.down];
		auto ordered_dirs = randomShuffle(orthogonal_dirs, rng)
			~randomShuffle(diagonal_dirs, rng);
		Point[8] ordered_points;

		foreach (int i, e; ordered_dirs) {
			ordered_points[i].x = x+dir_to_point[e].x;
			ordered_points[i].y = y+dir_to_point[e].y;
		}
		return ordered_points;
	}
}
