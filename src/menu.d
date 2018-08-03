import std.algorithm.comparison;
import std.stdio; // XXX.
import std.random; // XXX.
import std.datetime; // XXX.
import std.math;
import std.conv;
import std.container;
import util;
import term;
import main;
import game;
import tile;
import actor;
import item;

// TODO: Function that will cover both `mainMenu()` and `inGameMenu()`.
void mainMenu()
{
	immutable string[] label_strs = [
		"New Game",
		"Load Game",
		"Quit",
	];
	immutable int labels_x = 35;
	immutable int labels_y = 22/2-cast (int) label_strs.length/2;
	int pos = 0;
	Key key;
	do {
		term.clear();
		foreach (int i, v; label_strs) {
			term.write(labels_x, labels_y+i, v, i == pos? Color.red : Color.white);
		}
		key = term.readKey();
		if (key == Key.digit_2) {
			pos = umod(pos+1, cast (int) label_strs.length);
		} else if (key == Key.digit_8) {
			pos = umod(pos-1, cast (int) label_strs.length);
		} else if (key == Key.escape) {
			pos = cast (int) label_strs.length-1; // Last label is "Quit".
		}
		if (key == Key.enter) {
			if (pos == 0) {
				newGameMenu();
			} else if (pos == 1) {
				//loadGameMenu();
			}
		}
		// `pos == 2` means quit.
	} while (key != Key.enter || pos != 2);
}

void drawMainMenu()
{

}

void newGameMenu()
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

	main_game = new Game;
	main_game.player = new PlayerActor;
	main_game.player.items.insertBack(new LightkatanaItem);

	do {
		if (key == Key.digit_4) {
			ActorStat stat = is_right_side?
				right_stats[pos] : left_stats[pos];
			newGameMenuDecrementStat(main_game.player.stats, stat,
				attribute_points_num, skill_points_num,
				knowledge_points_num);
		} else if (key == Key.digit_6) {
			ActorStat stat = is_right_side?
				right_stats[pos] : left_stats[pos];
			newGameMenuIncrementStat(main_game.player.stats, stat,
				attribute_points_num, skill_points_num,
				knowledge_points_num);
		} else if ((key >= Key.a && key <= Key.Z) || key == Key.space) {
			if (name.length < max_name_length) {
				name ~= key_to_chr[key];
			}
		} else if (key == Key.backspace) {
			if (name.length > 0) {
				name = name[0 .. $-1];
			}
		}
		drawNewGameMenu(name, main_game.player.stats, pos,
			attribute_points_num, skill_points_num, knowledge_points_num);
		string[term_height] left_strs, right_strs;
		for (int i = 0; i < term_height; ++i) {
			left_strs[i] = (left_stats[i] == ActorStat.none)?
				"" : "  "~main_game.player.stats.toString(left_stats[i]);
			right_strs[i] = (right_stats[i] == ActorStat.none)?
				"" : "  "~main_game.player.stats.toString(right_stats[i]);
		}
		dualList(left_strs, right_strs, key, pos, is_right_side);
		key = term.readKey();
	} while (key != Key.enter && key != Key.escape);

	if (key == Key.enter) {
		main_game.spawn(main_game.player, 10, 10);
		auto rng = Random(
			cast(uint) Clock.currTime().fracSecs().total!"hnsecs");
		foreach (i; 1..10000) {
			int x = uniform(0, 300, rng);
			int y = uniform(0, 300, rng);
			main_game.map.getTile(x, y) = new WallTile;
		}
		foreach (i; 1..10000) {
			int x = uniform(0, 300, rng);
			int y = uniform(0, 300, rng);
			main_game.map.getTile(x, y).items.insert(new LightkatanaItem);
		}
		main_game.centerizeCamera(main_game.player.x, main_game.player.y);
		main_game.run();
	}
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

void newGameMenuIncrementStat(ActorStats stats, ActorStat stat,
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

void newGameMenuDecrementStat(ActorStats stats, ActorStat stat,
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

// Return false if quitting.
bool inGameMenu(Game game)
{
	immutable string[] label_strs = [
		"Return to Game",
		"Save Game and Quit",
		"Quit Game without Saving"
	];
	immutable int labels_x = 28;
	immutable int labels_y = 22/2-cast (int) label_strs.length/2;
	Key key;
	int pos = 0;
	do {
		term.clear();
		foreach (int i, v; label_strs) {
			term.write(labels_x, labels_y+i, v, i == pos);
		}
		key = term.readKey();
		if (key == Key.digit_2) {
			pos = umod(pos+1, cast (int) label_strs.length);
		} else if (key == Key.digit_8) {
			pos = umod(pos-1, cast (int) label_strs.length);
		} else if (key == Key.escape) {
			pos = cast (int) label_strs.length-1; // Last label is "Quit".
		}
	} while (key != Key.enter);

	if (pos == 1) {
		// TODO: Do saving here.
		return false;
	} else if (pos == 2) {
		return false;
	}

	return true;
}

void dualList(string[term_height] left_strs,
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

bool selectItem(Array!Item items, string header, ref int index)
{
	int pos = 0;
	Key key;
	drawSelectItem(items, header, pos);
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

void drawSelectItem(Array!Item items, string header, int pos)
{
	term.clear(); // TODO: Optimize. Can be done without clearing.
	term.write(0, 0, header);
	foreach (i; pos..(pos+min(items.length, term_height-2))) {
		term.write(1, i+1, index_to_chr[i]~" - "~items[i].name);
	}
}
