import std.algorithm.comparison;
import std.algorithm.sorting; // XXX.
import std.functional;
import std.array;
import std.stdio;
import std.file;
import std.random; // XXX.
import std.datetime; // XXX.
import std.math;
import std.conv;
import std.container;
import util;
import term;
import main;
import game;
import map;
import levelgen;
import tile;
import actor;
import actor_defs;
import body;
import stat;
import player;
import item;
import item_defs;
import ser;

// TODO: Function that will cover both `mainMenu()` and `inGameMenu()`.
void mainMenu()
{
	while(centeredList(["New Game", "Load Game", "Quit"],
		[toDelegate(&newGameMenu),
		toDelegate(&loadGameMenu),
		delegate bool() { return false; }]))
	{}
}

bool newGameMenu()
{
	immutable int max_name_length = 32;
	// XXX: Perhaps this could be optimized.
	immutable Stat[term_height] left_stats = [
		Stat.none, // 0.
		Stat.none, // 1.
		Stat.none, // 2.
		Stat.none, // 3.
		Stat.strength, // 4.
		Stat.dexterity, // 5.
		Stat.agility, // 6.
		Stat.endurance, // 7.
		Stat.reflex, // 8.
		Stat.observantness, // 9.
		Stat.intelligence, // 10.
		Stat.none, // 11.
		Stat.none, // 12.
		Stat.none, // 13.
		Stat.none, // 14.
		Stat.none, // 15.
		Stat.none, // 16.
		Stat.none, // 17.
		Stat.none, // 18.
		Stat.none, // 19.
		Stat.none, // 20.
		Stat.none, // 21.
		Stat.none, // 22.
		Stat.none, // 23.
	];
	immutable Stat[term_height] right_stats = [
		Stat.none, // 0.
		Stat.none, // 1.
		Stat.none, // 2.
		Stat.none, // 3.
		Stat.constructing, // 4.
		Stat.repairing, // 5.
		Stat.modding, // 6.
		Stat.hacking, // 7.
		Stat.none, // 8.
		Stat.striking, // 9.
		Stat.aiming, // 10.
		Stat.extrapolating, // 11.
		Stat.throwing, // 12.
		Stat.dodging, // 13.
		Stat.none, // 14.
		Stat.ballistics, // 15.
		Stat.explosives, // 16.
		Stat.lasers, // 17.
		Stat.plasma, // 18.
		Stat.electromagnetism, // 19.
		Stat.computers, // 20.
		Stat.none, // 21.
		Stat.none, // 22.
		Stat.none, // 23.
	];
	string name = "";
	//Stats stats = new Stats;
	Key key = Key.none;
	int pos = 4;
	int attribute_points_num = 3;
	int skill_points_num = 3;
	int knowledge_points_num = 5;
	bool is_right_side = false;

	//main_game = new Game;
	//main_game.player = new PlayerActor;
	//main_game.player.items.insertBack(new LightkatanaItem);
	PlayerActor player = new PlayerActor;
	player.insertItem(new PistolItem);
	player.insertItem(new LightkatanaItem);
	player.insertItem(new PistolBulletItem);
	player.insertItem(new PistolBulletItem);
	//player.items.insertBack(new PistolItem);
	//player.items.insertBack(new LightkatanaItem);
	//player.items.insertBack(new PistolClipItem);

	do {
		if (key == Key.digit_4) {
			Stat stat = is_right_side?
				right_stats[pos] : left_stats[pos];
			newGameMenuDecrementStat(player, stat,
				attribute_points_num, skill_points_num,
				knowledge_points_num);
		} else if (key == Key.digit_6) {
			Stat stat = is_right_side?
				right_stats[pos] : left_stats[pos];
			newGameMenuIncrementStat(player, stat,
				attribute_points_num, skill_points_num,
				knowledge_points_num);
		} else if ((key >= Key.a && key <= Key.Z) || key == Key.space) {
			if (name.length < max_name_length) {
				name ~= key_to_chr[key];
			}
		} else if (key == Key.backspace) {
			if (name.length > 0) {
				name = name[0..$-1];
			}
		}
		drawNewGameMenu(name, player, pos,
			attribute_points_num, skill_points_num, knowledge_points_num);
		string[term_height] left_strs, right_strs;
		for (int i = 0; i < term_height; ++i) {
			left_strs[i] = (left_stats[i] == Stat.none)?
				"" : "  "~player.stats.toString(left_stats[i]);
			right_strs[i] = (right_stats[i] == Stat.none)?
				"" : "  "~player.stats.toString(right_stats[i]);
		}
		dualListNonblocking(left_strs, right_strs, key, pos, is_right_side);
		key = term.readKey();
	} while ((key != Key.enter || name == "") && key != Key.escape);

	if (key == Key.enter) {
		Map map = new Map(100, 100);
		LevelGenerator generator = new LevelGenerator(map);
		generator.genNarrowCorridorsAndAaRectRooms();

		main_game = new Game(map);
		// TODO: Create a separate routine for spawning the player.
		main_game.player = player;
		main_game.player.player_name = name;
		map.spawn(player, generator.floors[0]);
		map.spawn(new LightsamuraiAiActor, map.zones[2][map.zones[2].length-1]);

		main_game.centerizeCamera(main_game.player.x, main_game.player.y);
		main_game.run();
	}

	return true;
}

void drawNewGameMenu(string name, PlayerActor player, int pos,
	int attribute_points_num, int skill_points_num, int knowledge_points_num)
{
	term.clear();
	term.write(dual_list_left_x, 0,
		"Create a new character:", Color.cyan, true);
	term.write(dual_list_left_x, 1, " Name: "~name, Color.white, true);
	term.write(dual_list_left_x, 3, " Attributes:", Color.cyan);
	term.write(dual_list_left_x, 12,
		" Attribute points: "~to!string(attribute_points_num),
		Color.cyan, true);
	term.write(dual_list_left_x, 13,
		" Skill points: "~to!string(skill_points_num),
		Color.cyan, true);
	term.write(dual_list_left_x, 14,
		" Knowledge points: "~to!string(knowledge_points_num),
		Color.cyan, true);
	term.write(dual_list_right_x, 3, " Technical skills:", Color.cyan);
	term.write(dual_list_right_x, 8, " Combat skills:", Color.cyan);
	term.write(dual_list_right_x, 14, " Knowledge:", Color.cyan);
}

void newGameMenuIncrementStat(PlayerActor player, Stat stat,
	ref int attribute_points_num,
	ref int skill_points_num,
	ref int knowledge_points_num)
{
	if (stat >= Stat.attributes_min
	&& stat <= Stat.attributes_max) {
		if (attribute_points_num > 0
		&& player.stats.trySet(stat, player.stats[stat]+1)) {
			--attribute_points_num;
		}
	} else if (((stat >= Stat.technical_skills_min
	&& stat <= Stat.technical_skills_max)
	|| (stat >= Stat.combat_skills_min
	&& stat <= Stat.combat_skills_max))) {
		if (skill_points_num > 0
		&& player.stats.trySet(stat, player.stats[stat]+1)) {
			--skill_points_num;
		}
	} else if (stat >= Stat.knowledges_min
	&& stat <= Stat.knowledges_max) {
		if (knowledge_points_num > 0
		&& player.stats.trySet(stat, player.stats[stat]+1)) {
			--knowledge_points_num;
		}
	} else {
		assert(false);
	}
}

void newGameMenuDecrementStat(PlayerActor player, Stat stat,
	ref int attribute_points_num,
	ref int skill_points_num,
	ref int knowledge_points_num)
{
	if (player.stats.trySet(stat, player.stats[stat]-1)) {
		if (stat >= Stat.attributes_min
		&& stat <= Stat.attributes_max) {
			++attribute_points_num;
		} else if ((stat >= Stat.technical_skills_min
		&& stat <= Stat.technical_skills_max)
		|| (stat >= Stat.combat_skills_min
		&& stat <= Stat.combat_skills_max)) {
			++skill_points_num;
		} else if (stat >= Stat.knowledges_min
		&& stat <= Stat.knowledges_max) {
			++knowledge_points_num;
		} else {
			assert(false);
		}
	}
}

bool loadGameMenu()
{
	//alias less = (string x, string y) => to!ulong(x[1..$-5]) < to!ulong(y[1..$-5]);
	// TODO: Sort the filenames.
	string[] filenames;
	foreach (DirEntry v; dirEntries("saves", "*.json", SpanMode.shallow)) {
		// TODO: Cache the save headers in additional files,
		// so the list of saves can be displayed
		// without reading the entire saves.
		++filenames.length;
		filenames[$-1] = v.name;
	}
	int pos = 0;
	bool result = centeredList(filenames, [], pos);
	if (!result) {
		return true;
	}
	Serializer serializer = new Serializer;
	main_game = Game.make(serializer, "Game");

	// Remove trailing ".json" then read.
	main_game.read(Game.filenameToId(filenames[pos])); 
	main_game.run();
	return true;
}

// Return false if quitting.
bool inGameMenu(Game game)
{
	int pos = 0;
	bool result = centeredList(
		["Return to Game", "Save Game and Quit", "Quit Game without Saving"],
		pos);
	if (!result) {
		return true;
	}
	if (pos == 1) {
		game.write();
		return false;
	}
	if (pos == 2) {
		return false;
	}
	return true;
}

bool centeredList(string[] labels, ref int pos)
{
	return centeredList(labels, [], pos);
}

bool centeredList(string[] labels, bool delegate()[] callbacks)
{
	int dummy;
	return centeredList(labels, callbacks, dummy);
}

bool centeredList(string[] labels, bool delegate()[] callbacks,
	ref int pos)
{
	Key key = Key.none;
	size_t longest_length = 0;
	foreach (v; labels) {
		longest_length = max(longest_length, v.length);
	}
	int labels_x = term_width/2-cast(int)longest_length/2;
	int labels_y = term_height/2-cast(int)labels.length/2;
	do {
		term.clear();
		foreach (int i, v; labels) {
			term.write(labels_x, labels_y+i, v, i == pos);
		}
		key = term.readKey();
		if (key == Key.digit_8) {
			pos = umod(pos-1, cast(int)labels.length);
		} else if (key == Key.digit_2) {
			pos = umod(pos+1, cast(int)labels.length);
		} else if (key == Key.enter) {
			if (callbacks.length > pos) {
				return callbacks[pos]();
			}
			return true;
		}
	} while (key != Key.escape);
	return false;
}

void dualListNonblocking(string[term_height] left_strs,
	string[term_height] right_strs,
	Key key, ref int pos, ref bool is_right_side)
{
	if (key == Key.digit_8) {
		if (is_right_side) {
			do {
				pos = umod(pos-1, term_height);
			} while (right_strs[pos] == "");
		} else {
			do {
				pos = umod(pos-1, term_height);
			} while (left_strs[pos] == "");
		}
	} else if (key == Key.digit_2) {
		if (is_right_side) {
			do {
				pos = umod(pos+1, term_height);
			} while (right_strs[pos] == "");
		} else {
			do {
				pos = umod(pos+1, term_height);
			} while (left_strs[pos] == "");
		}
	} else if (key == Key.tab) {
		is_right_side = !is_right_side;
		if (is_right_side) {
			while (right_strs[pos] == "") {
				pos = umod(pos-1, term_height);
			}
		} else {
			while (left_strs[pos] == "") {
				pos = umod(pos-1, term_height);
			}
		}
	}
	drawDualList(left_strs, right_strs, pos, is_right_side);
}

// XXX: Why `immutable`, not `enum`?
immutable int dual_list_left_x = 0;
immutable int dual_list_right_x = 40;

void drawDualList(string[term_height] left_strs,
	string[term_height] right_strs,
	int pos, bool is_right_side)
{
	for (int i = 0; i < term_height; ++i) {
		term.write(dual_list_left_x, i, left_strs[i],
			i == pos && !is_right_side);
		term.write(dual_list_right_x, i, right_strs[i],
			i == pos && is_right_side);
	}
}

bool selectItem(Array!Item items, string[int] appendices, string header, 
	ref int index)
{
	int pos = 0;
	Key key;

	drawSelectItem(items, appendices, header, pos);
	do {
		key = term.readKey();
		if (key == Key.escape) {
			return false;
		}
	} while (key_to_chr[key] == 0
	|| chr_to_index[key_to_chr[key]] >= items.length);

	index = chr_to_index[key_to_chr[key]];
	return true;
}

void drawSelectItem(Array!Item items, string[int] appendices, string header,
	int pos)
{
	term.clear();
	term.write(0, 0, header);

	foreach (i; pos..(pos+min(items.length, term_height-2))) {
		if ((i in appendices) !is null) {
			term.write(1, i+1,
				index_to_chr[i]~" - "~items[i].full_indefinite_name~appendices[i]);
		} else {
			term.write(1, i+1, index_to_chr[i]~" - "
				~items[i].full_indefinite_name);
		}
	}
}

Point selectTile(Game game, ref Key key, void delegate(int, int) draw,
	bool delegate(int, int, Key) get_is_terminated)
{
	int dx = 0, dy = 0;

	do {
		game.centerizeCamera(game.player.x+dx, game.player.y+dy);
		game.draw();

		draw(game.player.x+dx, game.player.y+dy);
		auto tile = game.map.getTile(game.player.x+dx, game.player.y+dy);
		if (tile.is_visible) {
			term.write(0, term_height-1, tile.displayed_name, Color.white, true);
		} else {
			term.write(0, term_height-1, "not visible", Color.black, true);
		}

		key = term.readKey();
		dx += key_to_point[key].x;
		dy += key_to_point[key].y;
	} while (!get_is_terminated(game.player.x+dx, game.player.y+dy, key));
	//} while (key != Key.escape && key != Key.enter);

	game.centerizeCamera(game.player.pos);
	return Point(game.player.x+dx, game.player.y+dy);
}
Point selectTile(Game game, void delegate(int, int) draw,
	bool delegate(int, int, Key) get_is_terminated)
{
	Key key;
	return selectTile(game, key, draw, get_is_terminated);
}
Point selectTile(Game game, ref Key key, void delegate(int, int) draw)
{
	return selectTile(game, key, draw, toDelegate(&selectTileGetIsTerminated));
}
Point selectTile(Game game, void delegate(int, int) draw)
{
	Key key;
	return selectTile(game, key, draw);
}

bool selectTileGetIsTerminated(int x, int y, Key key)
{
	return key == Key.escape || key == Key.enter;
}
