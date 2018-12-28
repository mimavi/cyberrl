import std.algorithm.comparison;
import std.functional;
import std.random;
import util;
import map;
import tile_defs;

// TODO: Clean up.
// TODO: Replace it completely with something better.

// XXX: Consider either renaming this file to `mapgen.d` or `map.d`
// to `level.d` and variables and types in similar fashion.

class LevelGenerator
{
	Map map;

	// XXX: Consider appropiateness of using this type of dynamic array here,
	// instead of the `Array` template.
	/*private*/ Point[] floors;
	private AaRect[] aarect_rooms;
	private Point[][] corridors;

	this(Map map)
	{
		this.map = map;
	}

	void genNarrowCorridorsAndAaRectRooms()
	{
		AaRect bounds = AaRect(1, 1, 98, 98);
		genAaRectRooms(bounds, uniform(50, 200), 10);
		genNarrowAaRoomCorridors(bounds, uniform(25, 100), 1, 5, 10);
		map.floodfill(aarect_rooms[0].x, aarect_rooms[0].y,
			&genNarrowCorridorsAndAaRectRoomsFill!1);

		enum max_attempts_per_room = 1000;
		foreach (e; aarect_rooms) {
			if (map.getTile(e.x, e.y).zone == 0) {
				foreach (i; 0..max_attempts_per_room) {
					Point p = Point(
						uniform!"[]"(e.x, e.x+e.width-1),
						uniform!"[]"(e.y, e.y+e.height-1),
					);
					if (genNarrowCorridor(bounds, p, 1, 10,
					&genNarrowCorridorsAndAaRectRoomsGetIsBlocking,
					&genNarrowCorridorsAndAaRectRoomsGetIsForbidden)) {
						break;
					}
				}
			}
			// XXX.
		}
		
		foreach (e; corridors) {
			genDoor(e[0]);
			genDoor(e[$-1]);
		}

		map.floodfill(aarect_rooms[0].x, aarect_rooms[0].y,
			&genNarrowCorridorsAndAaRectRoomsFill!2);

			//throw new Exception("Linking zones failed.");
		//genNarrowAaRoomCorridors(AaRect(1, 1, 98, 98), 
		// TODO: Find all zones then make sure they merge...
		// Getting specific arrays for zones will be needed.
		

		/*foreach (e; aarect_rooms) {
			if (map.getTile(e.x, e.y).zone == 0) {
			}
		}*/
	}

	// XXX: Perhaps this function could be moved to `map.d`.
	bool genNarrowCorridorsAndAaRectRoomsFill(alias zone)(int x, int y)
	{
		map.zones.length = max(map.zones.length, zone+1);

		if (map.getTile(x, y).is_walkable && map.getTile(x, y).zone != zone) {
			map.getTile(x, y).zone = zone;
			++map.zones[zone].length;
			map.zones[zone][$-1] = Point(x, y);
			return true;
		}
		return false;
	}

	// TODO: Ugly name. Fix this mess.
	bool genNarrowCorridorsAndAaRectRoomsGetIsBlocking(AaRect bounds,
		int x, int y)
	{
		return map.getTile(x, y).is_walkable && map.getTile(x, y).zone != 1;
	}

	// TODO: Ugly name as well.
	bool genNarrowCorridorsAndAaRectRoomsGetIsForbidden(AaRect bounds,
		int x, int y)
	{
		return !bounds.getIsInside(x, y);
	}

	// TODO: Use max attempts variable, not max attempts per room variable.
	int genAaRectRooms(AaRect bounds,
		int targeted_room_num, int max_attempts_per_room,
		int delegate() get_room_width, int delegate() get_room_height,
		bool delegate(Map, AaRect) get_is_room_valid)
	{
		int room_num = 0;

		foreach (i; 0..targeted_room_num) {
			foreach (ii; 0..max_attempts_per_room) {
				int width = get_room_width();
				int height = get_room_height();
				int x = uniform!"[]"(bounds.x, bounds.x+bounds.width-width);
				int y = uniform!"[]"(bounds.y, bounds.y+bounds.height-height);

				if (get_is_room_valid(map, AaRect(x, y, width, height))) {
						makeAaRectRoom(AaRect(x, y, width, height));
						break;
				}
			}
		}

		return room_num;
	}

	int genAaRectRooms(AaRect bounds,
		int targeted_room_num, int max_attempts_per_room)
	{
		return genAaRectRooms(bounds,
			targeted_room_num, max_attempts_per_room,
			toDelegate(&genAaRectRoomsGetRoomWidth),
			toDelegate(&genAaRectRoomsGetRoomHeight),
			toDelegate(&genAaRectRoomsGetIsRoomValid));
	}

	// TODO: Use a different distribution.
	int genAaRectRoomsGetRoomWidth()
	{
		return uniform(2, 10, rng);
	}
	alias genAaRectRoomsGetRoomHeight = genAaRectRoomsGetRoomWidth;

	bool genAaRectRoomsGetIsRoomValid(Map map, AaRect room)
	{
		foreach (i; 0..room.width+2) {
			foreach (ii; 0..room.height+2) {
				if (cast(FloorTile)map.getTile(room.x+i-1, room.y+ii-1)) {
					return false;
				}
			}
		}
		return true;
	}

	int genNarrowAaRoomCorridors(AaRect bounds,
		int targeted_corridor_num, int turn_chance_numer, int turn_chance_denom,
		int max_attempts_per_corridor)
	{
		//auto p = floors[uniform(0, floors.length, rng)];
		foreach (i; 0..targeted_corridor_num) {
			foreach (ii; 0..max_attempts_per_corridor) {
				auto room = aarect_rooms[uniform(0, aarect_rooms.length)];
				Point p = Point(
					uniform!"[]"(room.x, room.x+room.width-1),
					uniform!"[]"(room.y, room.y+room.height-1),
				);

				if (genNarrowCorridor(bounds, p, turn_chance_numer,
				turn_chance_denom)) {
					break;
				}
			}
		}

		/*foreach (e; corridors) {
			genDoor(e[0]);
			genDoor(e[$-1]);
		}*/

		return targeted_corridor_num;
	}

	bool genNarrowCorridor(AaRect bounds, Point p,
		int turn_chance_numer, int turn_chance_denom,
		bool delegate(AaRect, int, int) get_is_blocking,
		bool delegate(AaRect, int, int) get_is_forbidden)
	{
		auto dir = [Dir.left, Dir.right, Dir.up, Dir.down].choice(rng);

		do {
			p.x += dir_to_point[dir].x;
			p.y += dir_to_point[dir].y;
			//if (!bounds.get_is_inside(p)
			//!|| (!map.getTile(p).is_walkable && !map.getTile(p).is_default)) {
			if (get_is_forbidden(bounds, p.x, p.y)) {
				return false;
			}
		//} while (!map.getTile(p).is_default);
		} while (get_is_blocking(bounds, p.x, p.y));

		++corridors.length;

		do {
			++corridors[$-1].length;
			corridors[$-1][$-1] = p;

			//if (!bounds.get_is_inside(p)
			//|| (!map.getTile(p).is_walkable && !map.getTile(p).is_default)) {
			if (get_is_forbidden(bounds, p.x, p.y)) {
				--corridors.length;
				return false;
			}
			if (chance(turn_chance_numer, turn_chance_denom)) {
				dir = [turn_dir_left, turn_dir_right].choice(rng)[dir];
			}

			p.x += dir_to_point[dir].x;
			p.y += dir_to_point[dir].y;
		//} while (map.getTile(p).is_default);
		} while (!get_is_blocking(bounds, p.x, p.y));

		foreach (e; corridors[$-1]) {
			makeFloor(e);
		}
		
		return true;
	}

	bool genNarrowCorridor(AaRect bounds, Point p,
		int turn_chance_numer, int turn_chance_denom)
	{
		return genNarrowCorridor(bounds, p, turn_chance_numer, turn_chance_denom,
				&genNarrowCorridorGetIsBlocking, &genNarrowCorridorGetIsForbidden);
	}

	bool genNarrowCorridorGetIsBlocking(AaRect bounds, int x, int y)
	{
		return !map.getTile(x, y).is_default;
	}
	
	bool genNarrowCorridorGetIsForbidden(AaRect bounds, int x, int y)
	{
		return !bounds.getIsInside(x, y)
		|| (!map.getTile(x, y).is_walkable && !map.getTile(x, y).is_default);
	}

	bool genDoor(int x, int y)
	{
		if (map.getTile(x, y).is_walkable) {
			if (map.getTile(x-1, y).is_walkable
			&& map.getTile(x+1, y).is_walkable
			&& !map.getTile(x, y-1).is_walkable && map.getTile(x, y-1).is_static
			&& !map.getTile(x, y+1).is_walkable && map.getTile(x, y+1).is_static
			&& (map.getTile(x-2, y).is_walkable
			|| map.getTile(x+2, y).is_walkable)) {
				map.getTile(x, y) = new HDoorTile;
				return true;
			}

			if (map.getTile(x, y-1).is_walkable
			&& map.getTile(x, y+1).is_walkable
			&& !map.getTile(x-1, y).is_walkable && map.getTile(x-1, y).is_static
			&& !map.getTile(x+1, y).is_walkable && map.getTile(x+1, y).is_static
			&& (map.getTile(x, y-2).is_walkable
			|| map.getTile(x, y+2).is_walkable)) {
				map.getTile(x, y) = new VDoorTile;
				return true;
			}
		}

		return false;
	}
	bool genDoor(Point p) { return genDoor(p.x, p.y); }

	void makeAaRectRoom(AaRect rect)
	{
		foreach (i; 0..rect.width) {
			foreach (ii; 0..rect.height) {
				makeFloor(rect.x+i, rect.y+ii);
			}
		}
		++aarect_rooms.length;
		aarect_rooms[$-1] = rect;
	}

	void makeFloor(int x, int y)
	{
		map.getTile(x, y) = new FloorTile;
		++floors.length;
		floors[$-1] = Point(x, y);
	}
	void makeFloor(Point p) { return makeFloor(p.x, p.y); }
}
