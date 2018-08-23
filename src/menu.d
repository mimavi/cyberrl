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
import player;
import actor_defs;
import item;
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
	immutable ActorStat[term_height] left_stats = [
		ActorStat.none, // 0.
		ActorStat.none, // 1.
		ActorStat.none, // 2.
		ActorStat.none, // 3.
		ActorStat.strength, // 4.
		ActorStat.dexterity, // 5.
		ActorStat.agility, // 6.
		ActorStat.endurance, // 7.
		ActorStat.reflex, // 8.
		ActorStat.observantness, // 9.
		ActorStat.intelligence, // 10.
		ActorStat.none, // 11.
		ActorStat.none, // 12.
		ActorStat.none, // 13.
		ActorStat.none, // 14.
		ActorStat.none, // 15.
		ActorStat.none, // 16.
		ActorStat.none, // 17.
		ActorStat.none, // 18.
		ActorStat.none, // 19.
		ActorStat.none, // 20.
		ActorStat.none, // 21.
		ActorStat.none, // 22.
		ActorStat.none, // 23.
	];
	immutable ActorStat[term_height] right_stats = [
		ActorStat.none, // 0.
		ActorStat.none, // 1.
		ActorStat.none, // 2.
		ActorStat.none, // 3.
		ActorStat.constructing, // 4.
		ActorStat.repairing, // 5.
		ActorStat.modding, // 6.
		ActorStat.hacking, // 7.
		ActorStat.none, // 8.
		ActorStat.striking, // 9.
		ActorStat.aiming, // 10.
		ActorStat.extrapolating, // 11.
		ActorStat.throwing, // 12.
		ActorStat.dodging, // 13.
		ActorStat.none, // 14.
		ActorStat.ballistics, // 15.
		ActorStat.explosives, // 16.
		ActorStat.lasers, // 17.
		ActorStat.plasma, // 18.
		ActorStat.electromagnetism, // 19.
		ActorStat.computers, // 20.
		ActorStat.none, // 21.
		ActorStat.none, // 22.
		ActorStat.none, // 23.
	];
	string name = "";
	//ActorStats stats = new ActorStats;
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

	do {
		if (key == Key.digit_4) {
			ActorStat stat = is_right_side?
				right_stats[pos] : left_stats[pos];
			newGameMenuDecrementStat(player.stats, stat,
				attribute_points_num, skill_points_num,
				knowledge_points_num);
		} else if (key == Key.digit_6) {
			ActorStat stat = is_right_side?
				right_stats[pos] : left_stats[pos];
			newGameMenuIncrementStat(player.stats, stat,
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
		drawNewGameMenu(name, player.stats, pos,
			attribute_points_num, skill_points_num, knowledge_points_num);
		string[term_height] left_strs, right_strs;
		for (int i = 0; i < term_height; ++i) {
			left_strs[i] = (left_stats[i] == ActorStat.none)?
				"" : "  "~player.stats.toString(left_stats[i]);
			right_strs[i] = (right_stats[i] == ActorStat.none)?
				"" : "  "~player.stats.toString(right_stats[i]);
		}
		dualListNonblocking(left_strs, right_strs, key, pos, is_right_side);
		key = term.readKey();
	} while (key != Key.enter && key != Key.escape);

	if (key == Key.enter) {
		Map map = new Map(100, 100);
		LevelGenerator generator = new LevelGenerator(map);
		generator.genAaRectRooms(AaRect(1, 1, 99, 99), 500, 10);
		generator.genNarrowAaRoomCorridors(AaRect(1, 1, 99, 99), 250, 1, 5, 10);

		main_game = new Game(map);
		// TODO: Create a separate routine for spawning the player.
		map.spawn(player, generator.floors[0]);
		main_game.player = player;

		main_game.centerizeCamera(main_game.player.x, main_game.player.y);
		main_game.run();
	}

	return true;
}

void drawNewGameMenu(string name, ActorStats stats, int pos,
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

void newGameMenuIncrementStat(ref ActorStats stats, ActorStat stat,
	ref int attribute_points_num,
	ref int skill_points_num,
	ref int knowledge_points_num)
{
	if (stat >= ActorStat.attributes_min
	&& stat <= ActorStat.attributes_max) {
		if (attribute_points_num > 0
		&& stats.trySet(stat, stats[stat]+1)) {
			--attribute_points_num;
		}
	} else if (((stat >= ActorStat.technical_skills_min
	&& stat <= ActorStat.technical_skills_max)
	|| (stat >= ActorStat.combat_skills_min
	&& stat <= ActorStat.combat_skills_max))) {
		if (skill_points_num > 0
		&& stats.trySet(stat, stats[stat]+1)) {
			--skill_points_num;
		}
	} else if (stat >= ActorStat.knowledges_min
	&& stat <= ActorStat.knowledges_max) {
		if (knowledge_points_num > 0
		&& stats.trySet(stat, stats[stat]+1)) {
			--knowledge_points_num;
		}
	} else {
		assert(false);
	}
}

void newGameMenuDecrementStat(ref ActorStats stats, ActorStat stat,
	ref int attribute_points_num,
	ref int skill_points_num,
	ref int knowledge_points_num)
{
	if (stats.trySet(stat, stats[stat]-1)) {
		if (stat >= ActorStat.attributes_min
		&& stat <= ActorStat.attributes_max) {
			++attribute_points_num;
		} else if ((stat >= ActorStat.technical_skills_min
		&& stat <= ActorStat.technical_skills_max)
		|| (stat >= ActorStat.combat_skills_min
		&& stat <= ActorStat.combat_skills_max)) {
			++skill_points_num;
		} else if (stat >= ActorStat.knowledges_min
		&& stat <= ActorStat.knowledges_max) {
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
	main_game = Game.make(serializer);

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

bool selectItem(Array!Item items, string[int] appends, string header, 
	ref int index)
{
	int pos = 0;
	Key key;

	drawSelectItem(items, appends, header, pos);
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

void drawSelectItem(Array!Item items, string[int] appends, string header,
	int pos)
{
	term.clear(); // TODO: Optimize. Can be done without clearing.
	term.write(0, 0, header);

	foreach (i; pos..(pos+min(items.length, term_height-2))) {
		if ((i in appends) !is null) {
			term.write(1, i+1, index_to_chr[i]~" - "~items[i].name~appends[i]);
		} else {
			term.write(1, i+1, index_to_chr[i]~" - "~items[i].name);
		}
	}
}
