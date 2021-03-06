//import iteration = std.algorithm.iteration;
import std.functional;
import std.container;
import std.random;
import std.range;
import std.math;
import util;
import ser;
import term;
import game;
import tile;
import tile_defs;
import actor;
import item;

class Map
{
	mixin (serializable);

	@noser Game game;
	Array!Point visibles;
	Point[][] zones;

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
				getTile(x, y) = new DefaultWallTile;
			}
		}
	}

	void beforesave(Serializer serializer) {}
	void beforeload(Serializer serializer) {}
	void aftersave(Serializer serializer) {}
	void afterload(Serializer serializer) {}

	void init(Game game)
	{
		this.game = game;
		foreach (e; actors[]) {
			e.init_(this);
		}
	}

	void spawn(Actor actor, int x, int y)
	{
		//actor.map = this;
		actors.insertBack(actor);
		actor.init_(this, x, y);
	}
	void spawn(Actor actor, Point p) { spawn(actor, p.x, p.y); }

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
		for (int i = 0; i < width; ++i) {
			for (int ii = 0; ii < height; ++ii) {
				getTile(src_x+i, src_y+ii).draw(dest_x+i, dest_y+ii);
			}
		}
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

	// XXX: Is the existence of `range` necessary?
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

			if (!was_blocking && !tile.is_transparent) {
				fovScan(center_x, center_y, dir_c, dir_r, row+1, range, vert,
					callback, start_slope, (cell+0.5)/(row-0.5));
				was_blocking = true;
			} else if (was_blocking && tile.is_transparent) {
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
		bool delegate(int, int) get_is_blocking,
		Point[8] delegate(int, int) get_next_coords)
	{
		// XXX: Is this a stack??? Consider renaming it to `queue`...
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
			foreach (ee; get_next_coords(e.x, e.y)) {
				// Target tile need not be passable
				// to be reachable in this routine.
				if (ee.x == target_x && ee.y == target_y) {
					if (get_is_blocking(ee.x, ee.y)) {
						return [];
					}

					Point[] result = [Point(source_x, source_y)];
					result.length = steps[e.x+e.y*width]+2;
					result[$-1] = Point(target_x, target_y);

					for ({Point cur = e; int ii = 0;}
					cur.x != source_x || cur.y != source_y;
					cur = links[cur.x+cur.y*width], ++ii) {
						result[$-2-ii] = cur;
					}
					return result;
				}

				if (!get_is_blocking(ee.x, ee.y)
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
	Point[] findPath(int source_x, int source_y, int target_x, int target_y)
	{
		return findPath(source_x, source_y, target_x, target_y,
			&findPathGetIsBlocking,
			&findPathGetNextCoords);
	}

	bool findPathGetIsBlocking(int x, int y)
	{
		return !getTile(x, y).is_walkable;
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

	// The algorithm is based on Bresenham line algorithm.
	// XXX: Perhaps use ranges instead of just returning an array?
	// TODO: Add output contract for `length` of result.
	Point[] castRay(int source_x, int source_y, int target_x, int target_y,
		bool delegate(int, int) get_is_blocking)
	out (result; result.length >= 1)
	{
		if (source_x == target_x && source_y == target_y) {
			return [Point(source_x, source_y)];
		}

		Point[] result;
		int err = 0;
		int dx = target_x-source_x;
		int dy = target_y-source_y;

		if (abs(target_x-source_x) >= abs(target_y-source_y)) {
			int y = source_y;
			//foreach (i; 0..(abs(dx)+1)) {
			for (int i = 0; ; ++i) {
				int x = source_x+i*sgn(dx);
				++result.length;
				result[$-1] = Point(x, y);

				if (get_is_blocking(x, y)) {
					return result;
				}

				if (2*(err+abs(dy)) < abs(dx)) {
					err = err+abs(dy);
				} else {
					err = err+abs(dy)-abs(dx);
					y += sgn(dy);
				}
			}
		} else {
			int x = source_x;
			//foreach (i; 0..(abs(dy)+1)) {
			for (int i = 0; ; ++i) {
				int y = source_y+i*sgn(dy);
				++result.length;
				result[$-1] = Point(x, y);

				if (get_is_blocking(x, y)) {
					return result;
				}

				if (2*(err+abs(dx)) < abs(dy)) {
					err = err+abs(dx);
				} else {
					err = err+abs(dx)-abs(dy);
					x += sgn(dx);
				}
			}
		}
		//return result;
	}
	Point[] castRay(Point source_p, Point target_p,
		bool delegate(int, int) get_is_blocking)
	{
		return castRay(source_p.x, source_p.y, target_p.x, target_p.y,
			get_is_blocking);
	}

	bool castRayGetIsblocking(int x, int y)
	{
		return getTile(x, y).is_walkable;
	}

	void floodfill(int x, int y, bool delegate(int, int) fill)
	{
		// XXX: Perhaps a linked list could perform better here.
		Point[] queue = [Point(x, y)];

		for (int i = 0; i < queue.length; ++i) {
			auto e = queue[i];
			if (!fill(e.x, e.y)) {
				continue;
			}

			queue.length += 2;
			queue[$-2] = Point(e.x, e.y-1);
			queue[$-1] = Point(e.x, e.y+1);

			int ii;
			for (ii = 1; fill(e.x-ii, e.y); ++ii) {
				queue.length += 2;
				queue[$-2] = Point(e.x-ii, e.y-1);
				queue[$-1] = Point(e.x-ii, e.y+1);
			}
			queue.length += 2;
			queue[$-2] = Point(e.x-ii, e.y-1);
			queue[$-1] = Point(e.x-ii, e.y+1);

			for (ii = 1; fill(e.x+ii, e.y); ++ii) {
				queue.length += 2;
				queue[$-2] = Point(e.x+ii, e.y-1);
				queue[$-1] = Point(e.x+ii, e.y+1);
			}
			queue.length += 2;
			queue[$-2] = Point(e.x+ii, e.y-1);
			queue[$-1] = Point(e.x+ii, e.y+1);
		}
	}
	void floodfill(Point p, bool delegate(int, int) fill)
	{
		floodfill(p.x, p.y, fill);
	}

	// XXX: Perhaps this function will be better as `const`?
	ref Tile getTile(int x, int y) pure
	{
		if (x < 0 || y < 0 || x >= _width || y >= _width) {
			tmp = new WallTile;
			return tmp;
		}
		return tiles[x+y*_width];
	}
	ref Tile getTile(Point p) { return getTile(p.x, p.y); }
}
