import std.typecons;
import util;
import main;
import menu;
import ser;
import term;
import tile;
import actor;
import body;

class PlayerActor : Actor
{
	mixin InheritedSerializable;

	enum body_parts_text_x = 24;
	enum body_parts_text_y = 1;
	enum body_part_text_width = 11;

	string _player_name;

	@property override Symbol symbol() const /*pure*/
		{ return Symbol('@', Color.white, Color.black, true); }
	@property override string name() const /*pure*/ { return "you"; }
	@property override string definite_name() const /*pure*/ { return name; }
	@property override string indefinite_name() const /*pure*/ { return name; }
	@property override string possesive_pronoun() const /*pure*/
		{ return "your"; }
	@property string player_name() const /*pure*/ { return _player_name; }
	@property void player_name(string name) /*pure*/ { _player_name = name; }
	@property private string[int] item_appends() const /*pure*/
	{
		return [
			weapon_index: " (currently wielded)",
		];
	}

	this()
	{
		body_ = new HumanFleshyBody;
		super();
	}
	this(Serializer serializer) { this(); }

	override void initPos(int x, int y) /*pure*/
	{
		super.initPos(x, y);
		map.game.centerizeCamera(x, y);
	}

	override bool subupdate()
	{
		void fovCallback(int tile_x, int tile_y, Tile tile)
		{
			tile.is_visible = true;
			map.visibles.insertBack(Point(tile_x, tile_y));
		}

		foreach (e; map.visibles[]) {
			map.getTile(e).is_visible = false;
		}

		map.visibles.length = 0;
		map.fov(x, y, int.max, &fovCallback);

		bool has_acted = false;

		do {
			map.game.draw();
			auto key = term.readKey();
			if (key == Key.escape) {
				if (!menu.inGameMenu(map.game)) {
					return false;
				}
			} else if (key >= Key.digit_1 && key <= Key.digit_9) {
				if (key_to_point[key].x != 0 || key_to_point[key].y != 0) {
					has_acted = actHit(x+key_to_point[key].x, y+key_to_point[key].y);
				}
				if (!has_acted) {
					has_acted =
						actMoveTo(x+key_to_point[key].x, y+key_to_point[key].y);
				}
				if (!has_acted) {
					has_acted = actOpen(x+key_to_point[key].x, y+key_to_point[key].y);
				}
			} else if (key == Key.g) {
				int index;
				if (menu.selectItem(map.getTile(x, y).items, (string[int]).init,
				"Select item to pick up:", index)) {
					has_acted = actPickUp(index);
				}
			} else if (key == Key.d) {
				int index;
				if (menu.selectItem(items, item_appends, "Select item to drop:",
				index)) {
					has_acted = actDrop(index);
				}
			} else if (key == Key.w) {
				int index;
				if (menu.selectItem(items, item_appends, "Select item to wield:",
				index)) {
					has_acted = actWield(index);
				}
			} else if (key == Key.period) {
				has_acted = actWait();
			}
		} while (!has_acted);
		return true;
	}

	void drawBodyStatus()
	{
		term.write(body_parts_text_x,
			body_parts_text_y, " left arm",
			drawBodyStatusDamageArgs(HumanFleshyBodyPart.left_arm).expand,
			body_part_text_width);
		term.write(body_parts_text_x+body_part_text_width,
			body_parts_text_y, "   head",
			drawBodyStatusDamageArgs(HumanFleshyBodyPart.head).expand,
			body_part_text_width);
		term.write(body_parts_text_x+2*body_part_text_width,
			body_parts_text_y, " right arm",
			drawBodyStatusDamageArgs(HumanFleshyBodyPart.right_arm).expand,
			body_part_text_width);
		term.write(body_parts_text_x,
			body_parts_text_y+1, " left leg",
			drawBodyStatusDamageArgs(HumanFleshyBodyPart.left_leg).expand,
			body_part_text_width);
		term.write(body_parts_text_x+body_part_text_width,
			body_parts_text_y+1, "  torso",
			drawBodyStatusDamageArgs(HumanFleshyBodyPart.torso).expand,
			body_part_text_width);
		term.write(body_parts_text_x+2*body_part_text_width,
			body_parts_text_y+1, " right leg",
			drawBodyStatusDamageArgs(HumanFleshyBodyPart.right_leg).expand,
			body_part_text_width);
	}

	private Tuple!(Color, bool)
		drawBodyStatusDamageArgs(HumanFleshyBodyPart part) const /*pure*/
	{
		int percentage = 100-body_.getDamage(part)*100/body_.getMaxDamage(part);
		if (percentage == 100) {
			return tuple(Color.white, true);
		} else if (percentage >= 70) {
			return tuple(Color.yellow, true);
		} else if (percentage >= 30) {
			return tuple(Color.red, true);
		} else if (percentage > 0) {
			return tuple(Color.red, false);
		} else {
			return tuple(Color.black, true);
		}
	}

	override bool actOpen(int x, int y)
	{
		bool result = super.actOpen(x, y);
		if (result) {
			map.game.sendVisibleEventMsg(x, y, Color.yellow, false,
				"you open the door");
		}
		return result;
	}

	private string act_hit_prev_damage_str;

	override void onHitJustBefore(int x, int y, int part)
	{
		auto hittee = map.getTile(x, y).actor;
		act_hit_prev_damage_str = hittee.body_.getDamageStr(part);
	}

	override void onHitImpact(int x, int y, int part)
	{
		auto hittee = map.getTile(x, y).actor;
		string damage_str = hittee.body_.getDamageStr(part);
		if (damage_str == act_hit_prev_damage_str) {
			map.game.sendVisibleEventMsg([pos, hittee.pos],
				Color.white, true, "%1(1)|2$s hit %3(2)|4$s in %5$s %6$s"
				~" with %7$s %8$s!",
				definite_name, "somebody", hittee.definite_name, "somebody",
				hittee.possesive_pronoun, body_.getPartName(part),
				possesive_pronoun, items[weapon_index].name);
		} else {
			map.game.sendVisibleEventMsg([pos, hittee.pos],
				Color.white, true, "%2(1)|1$s hit %3(2)|1$s in %4$s %5$s"
				~" with %6$s %7$s and the part becomes %8$s!",
				"somebody", definite_name, hittee.definite_name,
				hittee.possesive_pronoun, body_.getPartName(part),
				possesive_pronoun, items[weapon_index].name, damage_str);
		}
	}

	override void onHitMiss(int x, int y)
	{
		auto hittee = map.getTile(x, y).actor;
		map.game.sendVisibleEventMsg([pos, hittee.pos],
			Color.white, false, "%2(1)|1$s miss %3(2)|1$s",
			"somebody", definite_name, hittee.definite_name);
	}

	override void onUnarmedHitImpact(int x, int y, int part)
	{
		auto hittee = map.getTile(x, y).actor;
		string damage_str = hittee.body_.getDamageStr(part);
		if (damage_str == act_hit_prev_damage_str) {
			map.game.sendVisibleEventMsg([pos, hittee.pos],
				Color.white, true, "%2(1)|1$s hit %3(2)|1$s in %4$s %5$s!",
				"somebody", definite_name, hittee.definite_name,
				hittee.possesive_pronoun, body_.getPartName(part));
		} else {
			map.game.sendVisibleEventMsg([pos, hittee.pos],
				Color.white, true, "%2(1)|1$s hit %3(2)|1$s in %4$s %5$s"
				~" and the part becomes %6$s!",
				"somebody", definite_name, hittee.definite_name,
				hittee.possesive_pronoun, body_.getPartName(part), damage_str);
		}
	}

	/*protected override void actHitSendHitMsg(const Actor target, int part,
		string prev_damage_str)
		/*pure*/
	/*{
		string damage_str = target.body_.getDamageStr(part);
		if (damage_str == prev_damage_str) {
			map.game.sendVisibleEventMsg([pos, target.pos],
				Color.white, true, "%1(1)|2$s hit %3(2)|4$s in %5$s %6$s"
				~" with %7$s %8$s!",
				definite_name, "somebody", target.definite_name, "somebody",
				target.possesive_pronoun, body_.getPartName(part),
				possesive_pronoun, items[weapon_index].name);
		} else {
			map.game.sendVisibleEventMsg([pos, target.pos],
				Color.white, true, "%2(1)|1$s hit %3(2)|1$s in %4$s %5$s"
				~" with %6$s %7$s and the part becomes %8$s!",
				"somebody", definite_name, target.definite_name,
				target.possesive_pronoun, body_.getPartName(part),
				possesive_pronoun, items[weapon_index].name, damage_str);
		}
	}

	protected override void actHitSendUnarmedHitMsg(const Actor target,
		int part, string prev_damage_str)
	{
		string damage_str = target.body_.getDamageStr(part);
		if (damage_str == prev_damage_str) {
			map.game.sendVisibleEventMsg([pos, target.pos],
				Color.white, true, "%2(1)|1$s hit %3(2)|1$s in %4$s %5$s!",
				"somebody", definite_name, target.definite_name,
				target.possesive_pronoun, body_.getPartName(part));
		} else {
			map.game.sendVisibleEventMsg([pos, target.pos],
				Color.white, true, "%2(1)|1$s hit %3(2)|1$s in %4$s %5$s"
				~" and the part becomes %6$s",
				"somebody", definite_name, target.definite_name,
				target.possesive_pronoun, body_.getPartName(part), damage_str);
		}
	}

	protected override void actHitSendMissMsg(const Actor target, int part)
		/*pure*/
	/*{
		map.game.sendVisibleEventMsg([pos, target.pos],
			Color.white, false, "%2(1)|1$s miss %3(2)|1$s",
			"somebody", definite_name, target.definite_name);
			//definite_name, "somebody", target.definite_name, "somebody");
	}*/

	/*private bool drawBodyStatusDamageToBright(int damage, int max_damage)
		const /*pure*/
	/*{
		int percentage = damage*100/max_damage;
		if (percentage == 100) {
			return true;
		} else if (percentage >= 75) {
			return false;
		} else if (percentage >= 50) {
			return true;
		} else if (percentage >= 25) {
			return true;
		} else if (percentage > 0) {
			return false;
		} else {
			return true;
		}
	}*/
}
