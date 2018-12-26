import std.typecons;
import util;
import main;
import menu;
import ser;
import term;
//import game;
import tile;
import item;
import actor;
import body;

class PlayerActor : Actor
{
	// TODO: Add contracts for `map` and `map.game`.
	//invariant(map !is null);
	//invariant(map.game !is null);

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
	@property override string possessive_pronoun() const /*pure*/
		{ return "your"; }
	@property string player_name() const /*pure*/ { return _player_name; }
	@property void player_name(string name) /*pure*/ { _player_name = name; }
	@property private string[int] item_appendices() const /*pure*/
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

	protected override void initPos(int x, int y) /*pure*/
	{
		super.initPos(x, y);
		map.game.centerizeCamera(x, y);
	}

	protected override bool updateRaw()
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
			} else if (key == Key.r) {
				int index;
				if (menu.selectItem(items, item_appendices, "Select item to load:",
				index)) {
					has_acted = actLoadAmmo(index);
				}
			} else if (key == Key.g) {
				int index;
				if (menu.selectItem(map.getTile(x, y).items, (string[int]).init,
				"Select item to pick up:", index)) {
					has_acted = actPickUp(index);
				}
			} else if (key == Key.d) {
				int index;
				if (menu.selectItem(items, item_appendices, "Select item to drop:",
				index)) {
					has_acted = actDrop(index);
				}
			} else if (key == Key.w) {
				int index;
				if (menu.selectItem(items, item_appendices, "Select item to wield:",
				index)) {
					has_acted = actWield(index);
				}
			} else if (key == Key.f) {

				if (weapon_index == -1) {
					/*map.game.msgs.insertBack(
						Msg("you have no weapon wielded to fire with",
							[], Color.cyan, false));*/

					map.game.sendMsg(Color.cyan, false, 
						"you have no weapon wielded to fire with");
				} else if (!items[weapon_index].can_shoot) {
					map.game.sendMsg(Color.cyan, false,
						"you cannot shoot with this weapon");
				} else {
					Point[] ray;
					bool was_terminated = false;
					bool getIsBlocking(int x, int y)
					{
						auto tile = map.getTile(x, y);
						return !tile.is_walkable || ((tile.actor !is null)
						&& tile.actor != this);
					}
					void drawShootLook(int x, int y)
					{
						bool has_passed_thru_not_visible = false;
						ray = map.castRay(this.x, this.y, x, y, &getIsBlocking);
						if (ray.length == 1) {
							map.game.setSymbolOnViewport(this.pos,
								Symbol('X', Color.green, true));
							return;
						}
						foreach (int i, e; ray[1..$-1]) {
							if (!map.getTile(e).is_visible) {
								has_passed_thru_not_visible = true;
								break;
							}
							map.game.setSymbolOnViewport(
								e, Symbol('X', Color.green, false));
						}
						if (!has_passed_thru_not_visible
						&& map.getTile(ray[$-1]).is_visible) {
							map.game.setSymbolOnViewport(ray[$-1],
								Symbol('X', Color.green, true));
						}
						if (ray[$-1] != Point(x, y)) {
							map.game.setSymbolOnViewport(x, y,
								Symbol('X', Color.yellow, true));
						}
					}
					bool getIsShootLookTerminated(int x, int y, Key key)
					{
						was_terminated = true;
						return key == Key.escape || key == Key.enter || key == Key.f;
					}

					Point target = menu.selectTile(
						map.game, &drawShootLook, &getIsShootLookTerminated);

					if (!was_terminated && target.x == x && target.y == y) {
						map.game.sendMsg(Color.cyan, false,
							"you cannot shoot at yourself with this command");
						continue;
					}

					map.game.centerizeCamera(target);
					has_acted = actShoot(target);
					map.game.centerizeCamera(this.pos);
				}
			} else if (key == Key.l) {
				void drawLook(int x, int y)
				{
					map.game.setSymbolOnViewport(x, y, Symbol('X', Color.green, true));
				}
				bool getIsLookTerminated(int x, int y, Key key)
				{
					return key == Key.escape || key == Key.enter || key == Key.l;
				}

				menu.selectTile(map.game, &drawLook, &getIsLookTerminated);
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
		Actor hittee = map.getTile(x, y).actor;
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
				hittee.possessive_pronoun, body_.getPartName(part),
				possessive_pronoun, items[weapon_index].name);
		} else {
			map.game.sendVisibleEventMsg([pos, hittee.pos],
				Color.white, true, "%2(1)|1$s hit %3(2)|1$s in %4$s %5$s"
				~" with %6$s %7$s and the part becomes %8$s!",
				"somebody", definite_name, hittee.definite_name,
				hittee.possessive_pronoun, body_.getPartName(part),
				possessive_pronoun, items[weapon_index].name, damage_str);
		}
	}

	override void onHitMiss(int x, int y)
	{
		Actor hittee = map.getTile(x, y).actor;
		map.game.sendVisibleEventMsg([pos, hittee.pos],
			Color.white, false, "%2(1)|1$s miss %3(2)|1$s",
			"somebody", definite_name, hittee.definite_name);
	}

	override void onUnarmedHitImpact(int x, int y, int part)
	{
		Actor hittee = map.getTile(x, y).actor;
		string damage_str = hittee.body_.getDamageStr(part);

		if (damage_str == act_hit_prev_damage_str) {
			map.game.sendVisibleEventMsg([pos, hittee.pos],
				Color.white, true, "%2(1)|1$s hit %3(2)|1$s in %4$s %5$s!",
				"somebody", definite_name, hittee.definite_name,
				hittee.possessive_pronoun, hittee.body_.getPartName(part));
		} else {
			map.game.sendVisibleEventMsg([pos, hittee.pos],
				Color.white, true, "%2(1)|1$s hit %3(2)|1$s in %4$s %5$s"
				~" and the part becomes %6$s!",
				"somebody", definite_name, hittee.definite_name,
				hittee.possessive_pronoun, hittee.body_.getPartName(part),
				damage_str);
		}
	}

	private string act_shoot_prev_damage_str;

	override void onShootImpactOnActorJustBefore(int x, int y, Item projectile,
		int part)
	{
		Actor target = map.getTile(x, y).actor;
		act_hit_prev_damage_str = target.body_.getDamageStr(part);
	}

	override void onShootImpactOnActor(int x, int y, Item projectile, int part)
	{
		Actor target = map.getTile(x, y).actor;
		string damage_str = target.body_.getDamageStr(part);

		if (damage_str == act_shoot_prev_damage_str) {
			map.game.sendVisibleEventMsg(target.pos,
				Color.white, true, "the %1$s hits %2$s in %3$s %4$s!",
				projectile.name, target.definite_name,
				target.possessive_pronoun, target.body_.getPartName(part));
		} else {
			map.game.sendVisibleEventMsg(target.pos,
				Color.white, true, "the %1$s hits %2$s in %3$s %4$s"
				~" and the part becomes %5$s!",
				projectile.name, target.definite_name, target.possessive_pronoun,
				target.body_.getPartName(part), damage_str);
		}
	}
}
