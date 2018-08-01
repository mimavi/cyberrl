import std.algorithm.comparison;
import std.typecons;
import std.container;
import std.math;
import std.conv;
import util;
import term;
import actor;
import item;

immutable string[] main_menu_labels = [
	"New Game",
	"Load Game",
	"Quit",
];

/*void mainMenu()
{
	int pos = 0;
	Key key;
	do {
		drawMainMenu(pos);
		key = term.readKey();
		if (key == Key.escape) {
			// "Quit" is always the last label.
			pos = main_menu_labels.length-1;
		} else if (key == Key.digit_2) {
			pos = umod(pos+1, main_menu_labels.length);
		} else if (key == Key.digit_8) {
			pos = umod(pos-1, main_menu_labels.length);
		} else if (key == Key.enter) {
			switch(pos) {
				case 0:
					newGameMenu();
					break;
				case 1:
					loadGameMenu();
					break;
				case 2:
					break;
				default:
					break;
			}
		}
	} while (key != Key.enter || pos != main_menu_labels.length-1);
}

void drawMainMenu(int pos)
{
	term.clear();
	int x = term_width / 2 - ("Load Game").length / 2;
	int y = term_height / 2 - main_menu_labels.length / 2;
	foreach (int i, v; main_menu_labels) {
		term.write(x, y+i, main_menu_labels[i],
			Color.white, Color.black, i == pos);
	}
}*/

immutable int left_dual_list_x = 0;
immutable int right_dual_list_x = 40;

bool dualList(string[] left_strs, string[] right_strs, int pos,
	bool is_right_side, void function(Key, int) handle) {
	Key key;
	do {
		drawDualList(left_strs, right_strs, pos, is_right_side);
		key = term.readKey();
	} while(key != Key.enter && key != Key.escape);
	return true;
}

void drawDualList(string[] left_strs, string[] right_strs,
	//Color left_colors, Color right_colors,
	//Color left_bg_colors, Color right_bg_colors,
	//Color left_is_brights, Color right_is_brights)
	int pos, bool is_right_side)
{
	term.clear();
	for(int i = 0; i < term.term_height; ++i) {
		term.write(left_dual_list_x, i, left_strs[i]);
		term.write(right_dual_list_x, i, right_strs[i]);
	}
}

// Following code is poorly written.
// XXX: Sanitize it.

/*immutable int new_game_menu_max_name_length = 32;
immutable int new_game_menu_right_side_x = 40;
immutable int new_game_menu_name_y = 1;
immutable int new_game_points_y = 12;
immutable int new_game_menu_instructions_y = 21;

void newGameMenu()
{
	int attribute_points_num = 3;
	int skill_points_num = 3;
	int knowledge_points_num = 3;
	int pos = 4;
	bool is_left_side = true;
	string name = "";
	ActorStats stats = new ActorStats;
	Key key = Key.none;
	do {
		term.clear();
		for (int i = 0; i < term.term_height; ++i) {
			Tuple!(bool, int*, string, Color, bool) label =
				getNewGameMenuLeftSideLabel(i, pos, is_left_side, name,
					stats);
			bool is_valid_cursor_pos = label[0];
			int *trait = label[1];
			string str = label[2];
			Color color = label[3];
			bool is_bright = label[4];
			term.write(0, i, str, color, is_bright);

			label = getNewGameMenuRightSideLabel(i, pos, is_left_side, name,
				stats);
			is_valid_cursor_pos = label[0];
			str = label[2];
			color = label[3];
			is_bright = label[4];
			term.write(new_game_menu_right_side_x, i, str, color,
				is_bright);
		}

		// Name.
		term.write(0, new_game_menu_name_y, " Name: ", Color.cyan);
		term.write((" Name: ").length, new_game_menu_name_y, name,
			Color.white, true);

		// Attribute, skill and knowledge points.
		term.write(0, new_game_points_y, " Attribute points: ", Color.cyan);
		term.write((" Attribute points: ").length, new_game_points_y,
			to!string(attribute_points_num), Color.cyan, true);
		term.write(0, new_game_points_y+1, " Skill points: ", Color.cyan);
		term.write((" Attribute points: ").length, new_game_points_y+1,
			to!string(skill_points_num), Color.cyan, true);
		term.write(0, new_game_points_y+2, " Knowledge points: ",
			Color.cyan);
		term.write((" Attribute points: ").length, new_game_points_y+2,
			to!string(knowledge_points_num), Color.cyan, true);

		// TODO: Centerize these instructions.
		// Instructions.
		term.write(0, new_game_menu_instructions_y,
			"[UP], [DOWN] and [TAB] navigate through fields. "
			~"[ENTER] proceeds. [ESC] returns.", Color.blue, true);
		term.write(0, new_game_menu_instructions_y+1,
			"Alphabetic keys, [-] and [SPACE] append characters to name. "
			~"[BACKSPACE] deletes.", Color.blue, true);
		term.write(0, new_game_menu_instructions_y+2,
			"[LEFT] and [RIGHT] change traits. "
			~"Each change is worth either -1 or +1 point.",
			Color.blue, true);
		key = term.readKey();
		if (key == Key.digit_2) {
			if (is_left_side) {
				do {
					pos = umod(pos+1, term.term_height);
				} while (!getNewGameMenuLeftSideLabel(pos, pos, is_left_side,
					name, stats)[0]);
			} else {
				do {
					pos = umod(pos+1, term.term_height);
				} while (!getNewGameMenuRightSideLabel(pos, pos,
					is_left_side, name, stats)[0]);
			}
		} else if (key == Key.digit_8) {
			if (is_left_side) {
				do {
					pos = umod(pos-1, term.term_height);
				} while (!getNewGameMenuLeftSideLabel(pos, pos,
					is_left_side, name, stats)[0]);
			} else {
				do {
					pos = umod(pos-1, term.term_height);
				} while (!getNewGameMenuRightSideLabel(pos, pos,
					is_left_side, name, stats)[0]);
			}
		} else if (key == Key.tab) {
			is_left_side = !is_left_side;
			if (is_left_side) {
				while (!getNewGameMenuLeftSideLabel(pos, pos, is_left_side,
					name, stats)[0]) {
					pos = umod(pos-1, term.term_height);
				}
			} else {
				while (!getNewGameMenuRightSideLabel(pos, pos, is_left_side,
					name, stats)[0]) {
					pos = umod(pos-1, term.term_height);
				}
			}
		} else if (key == Key.digit_4) {
			if (is_left_side) {
				
			}
		} else if (key == Key.digit_6) {
			int *trait = getNewGameMenuLeftSideLabel(pos, pos,
				is_left_side, name, stats)[1];

			// All attributes are on the left side 
			if (is_left_side && attribute_points_num > 0) {
				--attribute_points_num;
				++*trait;
			}
		} else if (name.length > 0 && key == Key.backspace) {
			name = name[0 .. $-1];
		} else if (name.length < new_game_menu_max_name_length
		&& (key >= Key.a && key <= Key.Z
		|| key == Key.minus || key == Key.space)) {
			name ~= util.key_to_chr[key];
		}
	} while(key != Key.enter);
}

Tuple!(bool, int*, string, Color, bool) getNewGameMenuLeftSideLabel
	(int cur, int pos, bool is_left_side, string name, ActorStats stats)
{
	switch(cur) {
		case 0: return tuple(false, &stats.strength,
			"Create your character:", Color.cyan, true);
		//case 1: term.write(0, pos, "", Color.black, false);
		//case 1: return tuple(false, " Name: ", Color.cyan, false);
		//case 3: term.write(0, pos, "", Color.black, false);
		case 3: return tuple(false, &stats.strength, " Attributes:",
			Color.cyan, false);
		case 4: return tuple(true, &stats.strength, "  "~stats.strength_str,
			Color.white,
			pos == cur && is_left_side);
		case 5: return tuple(true, &stats.dexterity, "  "~stats.dexterity_str, Color.white,
			pos == cur && is_left_side);
		case 6: return tuple(true, &stats.agility, "  "~stats.agility_str, Color.white,
			pos == cur && is_left_side);
		case 7: return tuple(true, &stats.endurance, "  "~stats.endurance_str, 
			Color.white, pos == cur && is_left_side);
		case 8: return tuple(true, &stats.reflex, "  "~stats.reflex_str, Color.white,
			pos == cur && is_left_side);
		case 9: return tuple(true, &stats.observantness, "  "~stats.observantness_str,
			Color.white, pos == cur && is_left_side);
		case 10: return tuple(true, &stats.intelligence, "  "~stats.intelligence_str,
			Color.white, pos == cur && is_left_side);
		//case 12: return tuple(false, " Attribute points: "~
		default: return tuple(false, &stats.strength,
			"", Color.black, false);
	}
}

Tuple!(bool, int*, string, Color, bool) getNewGameMenuRightSideLabel
	(int cur, int pos, bool is_left_side, string name, ActorStats stats)
{
	switch(cur) {
		case 3: return tuple(false, &stats.strength, " Technical skills:",
			Color.cyan, false);
		case 4: return tuple(true, &stats.constructing, 
			"  "~stats.constructing_str, Color.white,
			pos == cur && !is_left_side);
		case 5: return tuple(true, &stats.repairing, 
			"  "~stats.repairing_str, Color.white,
			pos == cur && !is_left_side);
		case 6: return tuple(true, &stats.modding, "  "~stats.modding_str, Color.white,
			pos == cur && !is_left_side);
		case 7: return tuple(true, &stats.hacking, "  "~stats.hacking_str, Color.white,
			pos == cur && !is_left_side);
		case 8: return tuple(false, &stats.strength,
			" Combat skills:", Color.cyan, false);
		case 9: return tuple(true, &stats.striking, "  "~stats.striking_str, Color.white,
			pos == cur && !is_left_side);
		case 10: return tuple(true, &stats.aiming, "  "~stats.aiming_str, Color.white,
			pos == cur && !is_left_side);
		case 11: return tuple(true, &stats.extrapolating, "  "~stats.extrapolating_str,
			Color.white, pos == cur && !is_left_side);
		case 12: return tuple(true, &stats.throwing, "  "~stats.throwing_str, Color.white,
			pos == cur && !is_left_side);
		case 13: return tuple(true, &stats.dodging, "  "~stats.dodging_str, Color.white,
			pos == cur && !is_left_side);
		case 14: return tuple(false, &stats.strength,
			" Knowledge:", Color.cyan, false);
		case 15: return tuple(true, &stats.ballistics, "  "~stats.ballistics_str, Color.white,
			pos == cur && !is_left_side);
		case 16: return tuple(true, &stats.explosives, "  "~stats.explosives_str, Color.white,
			pos == cur && !is_left_side);
		case 17: return tuple(true, &stats.lasers, "  "~stats.lasers_str, Color.white,
			pos == cur && !is_left_side);
		case 18: return tuple(true, &stats.plasma, "  "~stats.plasma_str, Color.white,
			pos == cur && !is_left_side);
		case 19: return tuple(true, &stats.electromagnetism, "  "~stats.electromagnetism_str, 
			Color.white, pos == cur && !is_left_side);
		case 20: return tuple(true, &stats.computers,
			"  "~stats.computers_str, Color.white,
			pos == cur && !is_left_side);
		default: return tuple(false, &stats.strength, "",
			Color.black, false);
	}
}

void loadGameMenu()
{
}*/

void drawLoadGameMenu(int pos)
{
}

void quitMenu()
{
}

void drawQuitMenu()
{
}

bool selectItem(Array!Item items, string header, ref int index)
{
	int offset = 0;
	Key key;
	drawSelectItem(items, header, offset);
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

void drawSelectItem(Array!Item items, string header, int offset)
{
	term.clear(); // TODO: Optimize. Can be done without clearing.
	term.write(0, 0, header, Color.blue, true);
	foreach (i; offset..(offset+min(items.length, term_height-2))) {
		term.write(1, i+1, index_to_chr[i]~" - "~items[i].name);
	}
}
